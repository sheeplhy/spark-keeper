from __future__ import annotations

import json
import os
import secrets
import socket
import subprocess
import sys
import threading
import time
from datetime import datetime, timezone
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import urlsplit
from zoneinfo import ZoneInfo


ROOT = Path(__file__).resolve().parent
ENGINE_ROOT = ROOT / "engine"
TOKEN_PATH = ROOT / ".agent-token"
DATA_ROOT = Path(os.getenv("SPARK_DATA_DIR", str(ENGINE_ROOT))).resolve()
CONFIG_PATH = DATA_ROOT / "config.json"
STATE_PATH = DATA_ROOT / "storage-state.json"
ARTIFACTS_PATH = DATA_ROOT / "artifacts"
LOGIN_STATUS_PATH = ARTIFACTS_PATH / "login-status.json"
LOGIN_QR_PATH = ARTIFACTS_PATH / "login-qr.png"
RESULT_PATH = ARTIFACTS_PATH / "result.json"
SCHEDULES_PATH = DATA_ROOT / "schedules.json"
HOST = os.getenv("SPARK_AGENT_HOST", "0.0.0.0")
PORT = int(os.getenv("SPARK_AGENT_PORT", "8765"))
LOCAL_TZ = ZoneInfo(os.getenv("SPARK_TIMEZONE", "Asia/Shanghai"))
os.environ.setdefault("TASK_CONFIG", str(CONFIG_PATH))
os.environ.setdefault("ARTIFACTS_DIR", str(ARTIFACTS_PATH))
os.environ.setdefault("DOUYIN_STORAGE_STATE", str(STATE_PATH))


def _load_or_create_token() -> str:
    configured = os.getenv("SPARK_AGENT_TOKEN", "").strip()
    if configured:
        return configured
    if TOKEN_PATH.is_file():
        return TOKEN_PATH.read_text(encoding="utf-8").strip()
    token = secrets.token_urlsafe(24)
    TOKEN_PATH.write_text(token, encoding="utf-8")
    return token


TOKEN = _load_or_create_token()


class JobState:
    def __init__(self) -> None:
        self.lock = threading.Lock()
        self.process: subprocess.Popen[Any] | None = None
        self.kind: str | None = None
        self.started_at: str | None = None
        self.exit_code: int | None = None

    def snapshot(self) -> dict[str, Any]:
        with self.lock:
            running = self.process is not None and self.process.poll() is None
            return {
                "running": running,
                "kind": self.kind,
                "startedAt": self.started_at,
                "exitCode": None if running else self.exit_code,
                "loggedIn": STATE_PATH.is_file(),
                "configured": CONFIG_PATH.is_file(),
                "scheduleCount": len(_load_schedules()),
            }

    def start(self, kind: str, command: list[str], *, new_console: bool) -> bool:
        with self.lock:
            if self.process is not None and self.process.poll() is None:
                return False
            creation_flags = subprocess.CREATE_NEW_CONSOLE if new_console and os.name == "nt" else 0
            ARTIFACTS_PATH.mkdir(parents=True, exist_ok=True)
            log_path = ARTIFACTS_PATH / f"bridge-{kind}.log"
            log_stream = None if new_console else log_path.open("a", encoding="utf-8")
            self.process = subprocess.Popen(
                command,
                cwd=ENGINE_ROOT,
                stdout=log_stream,
                stderr=subprocess.STDOUT if log_stream else None,
                creationflags=creation_flags,
            )
            self.kind = kind
            self.started_at = datetime.now(timezone.utc).isoformat()
            self.exit_code = None
            process = self.process

        def monitor() -> None:
            exit_code = process.wait()
            if log_stream:
                log_stream.close()
            with self.lock:
                if self.process is process:
                    self.exit_code = exit_code

        threading.Thread(target=monitor, daemon=True).start()
        return True

    def stop(self) -> bool:
        with self.lock:
            if self.process is None or self.process.poll() is not None:
                return False
            self.process.terminate()
            return True


JOBS = JobState()
SCHEDULE_LOCK = threading.Lock()
LAST_SCHEDULE_RUN: dict[str, str] = {}


def _validate_task_config(raw: Any) -> dict[str, Any]:
    if not isinstance(raw, dict):
        raise ValueError("任务配置必须是 JSON 对象")
    targets = raw.get("targets")
    if not isinstance(targets, list) or not targets:
        raise ValueError("至少选择一个好友")
    if len(targets) > 100:
        raise ValueError("单个计划最多选择 100 个好友")
    allowed_types = {"text", "image", "douyin_sticker", "sticker", "random"}
    for index, target in enumerate(targets):
        if not isinstance(target, dict):
            raise ValueError(f"第 {index + 1} 个好友配置无效")
        name = target.get("name")
        messages = target.get("messages")
        if not isinstance(name, str) or not name.strip():
            raise ValueError(f"第 {index + 1} 个好友缺少昵称")
        if not isinstance(messages, list) or not messages:
            raise ValueError(f"好友 {name} 至少需要一条消息")
        for message in messages:
            if not isinstance(message, dict) or message.get("type") not in allowed_types:
                raise ValueError(f"好友 {name} 包含不支持的消息类型")
    return raw


def _atomic_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp_path = path.with_suffix(path.suffix + ".tmp")
    temp_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    temp_path.replace(path)


def _write_task_config(raw: dict[str, Any]) -> None:
    _atomic_json(CONFIG_PATH, raw)


def _load_schedules() -> list[dict[str, Any]]:
    if not SCHEDULES_PATH.is_file():
        return []
    try:
        data = json.loads(SCHEDULES_PATH.read_text(encoding="utf-8"))
        return data if isinstance(data, list) else []
    except (OSError, json.JSONDecodeError):
        return []


def _save_schedule(raw: Any) -> dict[str, Any]:
    if not isinstance(raw, dict):
        raise ValueError("计划必须是 JSON 对象")
    schedule_id = raw.get("id")
    hour = raw.get("hour")
    minute = raw.get("minute")
    if not isinstance(schedule_id, str) or not schedule_id.strip():
        raise ValueError("计划缺少 id")
    if not isinstance(hour, int) or not 0 <= hour <= 23:
        raise ValueError("小时必须在 0 到 23 之间")
    if not isinstance(minute, int) or not 0 <= minute <= 59:
        raise ValueError("分钟必须在 0 到 59 之间")
    task = _validate_task_config(raw.get("task"))
    schedule = {
        "id": schedule_id,
        "name": str(raw.get("name", "续火花计划"))[:80],
        "enabled": bool(raw.get("enabled", True)),
        "hour": hour,
        "minute": minute,
        "task": task,
    }
    with SCHEDULE_LOCK:
        schedules = [item for item in _load_schedules() if item.get("id") != schedule_id]
        schedules.append(schedule)
        _atomic_json(SCHEDULES_PATH, schedules)
    return schedule


def _scheduler_loop() -> None:
    while True:
        now = datetime.now(LOCAL_TZ)
        day_key = now.strftime("%Y-%m-%d")
        for schedule in _load_schedules():
            schedule_id = str(schedule.get("id", ""))
            if (
                schedule.get("enabled") is True
                and schedule.get("hour") == now.hour
                and schedule.get("minute") == now.minute
                and LAST_SCHEDULE_RUN.get(schedule_id) != day_key
            ):
                try:
                    task = _validate_task_config(schedule.get("task"))
                    _write_task_config(task)
                    if JOBS.start("scheduled-run", [sys.executable, str(ENGINE_ROOT / "run.py")], new_console=False):
                        LAST_SCHEDULE_RUN[schedule_id] = day_key
                except Exception as error:
                    print(f"[scheduler] 计划 {schedule_id} 无法启动: {error}")
        time.sleep(15)


class AgentHandler(BaseHTTPRequestHandler):
    server_version = "SparkKeeperAgent/0.2"

    def do_OPTIONS(self) -> None:
        self.send_response(HTTPStatus.NO_CONTENT)
        self._cors_headers()
        self.end_headers()

    def do_GET(self) -> None:
        path = urlsplit(self.path).path
        if path == "/health":
            self._json(HTTPStatus.OK, {"status": "ok", "version": "0.2.0", "engineReady": (ENGINE_ROOT / "run.py").is_file()})
            return
        if not self._authorized():
            return
        if path == "/status":
            self._json(HTTPStatus.OK, JOBS.snapshot())
            return
        if path == "/login/status":
            payload = _read_json(LOGIN_STATUS_PATH) or {"state": "idle", "message": "尚未开始登录"}
            payload["qrAvailable"] = LOGIN_QR_PATH.is_file()
            payload["loggedIn"] = STATE_PATH.is_file()
            self._json(HTTPStatus.OK, payload)
            return
        if path == "/login/qr":
            if not LOGIN_QR_PATH.is_file():
                self._json(HTTPStatus.NOT_FOUND, {"error": "二维码尚未生成"})
                return
            self._binary(HTTPStatus.OK, LOGIN_QR_PATH.read_bytes(), "image/png")
            return
        if path == "/task":
            self._json(HTTPStatus.OK, {"task": _read_json(CONFIG_PATH)})
            return
        if path == "/schedules":
            safe = [{key: value for key, value in item.items() if key != "task"} for item in _load_schedules()]
            self._json(HTTPStatus.OK, {"schedules": safe})
            return
        if path == "/result":
            self._json(HTTPStatus.OK, {"result": _read_json(RESULT_PATH)})
            return
        if path == "/logs":
            log_path = ARTIFACTS_PATH / "run.log"
            lines = log_path.read_text(encoding="utf-8", errors="replace").splitlines()[-120:] if log_path.is_file() else []
            self._json(HTTPStatus.OK, {"lines": [line.replace(TOKEN, "[令牌已隐藏]") for line in lines]})
            return
        self._json(HTTPStatus.NOT_FOUND, {"error": "接口不存在"})

    def do_POST(self) -> None:
        path = urlsplit(self.path).path
        if not self._authorized():
            return
        if path == "/login":
            LOGIN_QR_PATH.unlink(missing_ok=True)
            _atomic_json(LOGIN_STATUS_PATH, {"state": "starting", "message": "正在打开抖音"})
            started = JOBS.start("login", [sys.executable, str(ENGINE_ROOT / "scripts" / "login.py")], new_console=True)
            self._job_response(started, "扫码登录")
            return
        if path == "/run/dry":
            self._job_response(JOBS.start("dry-run", [sys.executable, str(ENGINE_ROOT / "run.py"), "--dry-run"], new_console=False), "检查任务")
            return
        if path == "/run":
            self._job_response(JOBS.start("run", [sys.executable, str(ENGINE_ROOT / "run.py")], new_console=False), "发送任务")
            return
        if path == "/stop":
            self._json(HTTPStatus.OK, {"stopped": JOBS.stop()})
            return
        if path == "/task":
            try:
                task = _validate_task_config(self._read_json())
                _write_task_config(task)
            except (ValueError, json.JSONDecodeError) as error:
                self._json(HTTPStatus.BAD_REQUEST, {"error": str(error)})
                return
            self._json(HTTPStatus.OK, {"saved": True})
            return
        if path == "/schedule":
            try:
                schedule = _save_schedule(self._read_json())
            except (ValueError, json.JSONDecodeError) as error:
                self._json(HTTPStatus.BAD_REQUEST, {"error": str(error)})
                return
            self._json(HTTPStatus.OK, {"saved": True, "id": schedule["id"]})
            return
        self._json(HTTPStatus.NOT_FOUND, {"error": "接口不存在"})

    def _job_response(self, started: bool, label: str) -> None:
        if not started:
            self._json(HTTPStatus.CONFLICT, {"error": "已有任务正在运行"})
            return
        self._json(HTTPStatus.ACCEPTED, {"started": True, "message": label})

    def _authorized(self) -> bool:
        if secrets.compare_digest(self.headers.get("Authorization", ""), f"Bearer {TOKEN}"):
            return True
        self._json(HTTPStatus.UNAUTHORIZED, {"error": "配对令牌无效"})
        return False

    def _read_json(self) -> Any:
        length = int(self.headers.get("Content-Length", "0"))
        if length <= 0 or length > 1_000_000:
            raise ValueError("请求内容为空或过大")
        return json.loads(self.rfile.read(length).decode("utf-8"))

    def _json(self, status: HTTPStatus, payload: dict[str, Any]) -> None:
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self._send(status, body, "application/json; charset=utf-8")

    def _binary(self, status: HTTPStatus, body: bytes, content_type: str) -> None:
        self._send(status, body, content_type)

    def _send(self, status: HTTPStatus, body: bytes, content_type: str) -> None:
        self.send_response(status)
        self._cors_headers()
        self.send_header("Content-Type", content_type)
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _cors_headers(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Authorization, Content-Type")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")

    def log_message(self, format_string: str, *args: Any) -> None:
        print(f"[agent] {self.address_string()} {format_string % args}")


def _read_json(path: Path) -> Any:
    if not path.is_file():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None


def _local_addresses() -> list[str]:
    addresses = {"127.0.0.1"}
    try:
        addresses.update(socket.gethostbyname_ex(socket.gethostname())[2])
    except OSError:
        pass
    return sorted(address for address in addresses if ":" not in address)


def main() -> None:
    threading.Thread(target=_scheduler_loop, daemon=True).start()
    print("火花管家电脑 Agent 已启动")
    for address in _local_addresses():
        print(f"手机同一 Wi-Fi 可填写：http://{address}:{PORT}")
    print(f"配对令牌：{TOKEN}")
    print("登录凭证只保存在电脑 desktop_agent/engine/storage-state.json")
    print("请勿在路由器中把 8765 端口映射到公网。")
    ThreadingHTTPServer((HOST, PORT), AgentHandler).serve_forever()


if __name__ == "__main__":
    main()

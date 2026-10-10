from __future__ import annotations

import asyncio
import json
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from playwright.async_api import Page, async_playwright


DOUYIN_URL = "https://www.douyin.com/"
DATA_ROOT = Path(os.getenv("SPARK_DATA_DIR", str(PROJECT_ROOT))).resolve()
ARTIFACTS = DATA_ROOT / "artifacts"
STATUS_PATH = ARTIFACTS / "login-status.json"
QR_PATH = ARTIFACTS / "login-qr.png"
STORAGE_PATH = DATA_ROOT / "storage-state.json"
QR_SELECTORS = (
    '[class*="qrcode"] canvas',
    '[class*="qrcode"] img',
    '[class*="QRCode"] canvas',
    '[class*="QRCode"] img',
    'img[alt*="二维码"]',
    'canvas',
)


def _status(state: str, message: str, **extra: Any) -> None:
    ARTIFACTS.mkdir(parents=True, exist_ok=True)
    payload = {
        "state": state,
        "message": message,
        "updatedAt": datetime.now().astimezone().isoformat(),
        **extra,
    }
    temp = STATUS_PATH.with_suffix(".json.tmp")
    temp.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    temp.replace(STATUS_PATH)


async def login() -> None:
    ARTIFACTS.mkdir(parents=True, exist_ok=True)
    QR_PATH.unlink(missing_ok=True)
    _status("starting", "正在打开抖音登录页")
    try:
        async with async_playwright() as playwright:
            headless = os.getenv("SPARK_LOGIN_HEADLESS", "false").strip().lower() in {"1", "true", "yes", "on"}
            browser = await playwright.chromium.launch(headless=headless)
            context = await browser.new_context(locale="zh-CN")
            page = await context.new_page()
            await page.goto(DOUYIN_URL, wait_until="domcontentloaded", timeout=60_000)
            await _open_login(page)
            print("可直接扫描电脑浏览器中的二维码，也可在火花管家手机 App 查看同一二维码。")
            print("如抖音要求验证码、安全验证或 App 确认，请在可见浏览器/抖音 App 中手动完成。")

            seen_qr = False
            for attempt in range(180):
                if await _is_logged_in(page):
                    await context.storage_state(path=str(STORAGE_PATH.with_suffix(".json.tmp")))
                    STORAGE_PATH.with_suffix(".json.tmp").replace(STORAGE_PATH)
                    _status("logged_in", "登录成功，登录态仅保存在电脑")
                    print("登录成功，登录状态已安全保存在电脑。")
                    await asyncio.sleep(2)
                    await browser.close()
                    return

                verification = await _verification_text(page)
                if verification:
                    _status("verification_required", "需要在电脑浏览器或抖音 App 完成人工验证")
                else:
                    captured = await _capture_qr(page)
                    if captured:
                        seen_qr = True
                        _status("waiting_qr", "请使用抖音 App 扫码并确认")
                    elif seen_qr:
                        _status("waiting_confirmation", "二维码已扫描，请在抖音 App 确认")
                    else:
                        _status("starting", "正在等待登录二维码")

                if attempt and attempt % 30 == 0:
                    await _open_login(page)
                await asyncio.sleep(2)

            _status("error", "登录等待超时，请重新开始")
            await browser.close()
    except Exception as error:
        _status("error", f"登录程序出错：{type(error).__name__}")
        raise


async def _open_login(page: Page) -> None:
    login_button = page.get_by_text("登录", exact=True)
    if await login_button.count():
        try:
            if await login_button.first.is_visible():
                await login_button.first.click(timeout=8_000)
        except Exception:
            pass
    qr_login = page.get_by_text("扫码登录", exact=True)
    if await qr_login.count():
        try:
            if await qr_login.first.is_visible():
                await qr_login.first.click(timeout=5_000)
        except Exception:
            pass


async def _capture_qr(page: Page) -> bool:
    for selector in QR_SELECTORS:
        locator = page.locator(selector)
        count = min(await locator.count(), 8)
        for index in range(count):
            candidate = locator.nth(index)
            try:
                if not await candidate.is_visible():
                    continue
                box = await candidate.bounding_box()
                if not box or box["width"] < 100 or box["height"] < 100:
                    continue
                temp = QR_PATH.with_suffix(".png.tmp")
                await candidate.screenshot(path=str(temp), type="png")
                temp.replace(QR_PATH)
                return True
            except Exception:
                continue
    return False


async def _verification_text(page: Page) -> str | None:
    for text in ("安全验证", "完成验证", "验证码", "请在抖音 App 内确认", "登录确认"):
        locator = page.get_by_text(text, exact=False)
        try:
            if await locator.count() and await locator.first.is_visible():
                return text
        except Exception:
            continue
    return None


async def _is_logged_in(page: Page) -> bool:
    login_button = page.get_by_text("登录", exact=True)
    try:
        if await login_button.count() and await login_button.first.is_visible():
            return False
    except Exception:
        return False
    return "douyin.com" in page.url


if __name__ == "__main__":
    asyncio.run(login())

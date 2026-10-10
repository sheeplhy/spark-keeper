# 火花管家执行端

## Windows 本地模式

最简单的方式是依次双击：

1. `install-agent.cmd`：首次安装 Python 依赖和 Chromium。
2. `run-agent.cmd`：以后每次启动电脑 Agent。

电脑需要先安装 Python 3.11 或更高版本。

首次安装：

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\setup-windows.ps1
```

以后启动：

```powershell
.\start-agent.ps1
```

窗口会输出类似 `http://192.168.1.20:8765` 的局域网地址及配对令牌。手机和电脑需在同一 Wi‑Fi。若 Windows 防火墙询问，只允许“专用网络”，不要允许公共网络。

## API

- `GET /health`：无需令牌的最小健康检查。
- `GET /status`：登录、任务与自动计划状态。
- `POST /login`：电脑打开可见浏览器；同时把二维码裁剪图提供给手机。
- `GET /login/status`、`GET /login/qr`：手机获取登录状态和二维码。
- `POST /task`：保存一个兼容执行器的好友/消息任务。
- `POST /run/dry`：定位好友但不发送。
- `POST /run`：正式执行。
- `POST /schedule`：新增或更新电脑端自动计划。
- `GET /result`、`GET /logs`：获取脱敏结果和日志。
- `POST /stop`：停止当前任务。

除 `/health` 外均要求 `Authorization: Bearer <令牌>`。

## 安全

- `storage-state.json` 是高敏感登录凭据，只保存在执行端，禁止发送或提交 Git。
- App 只拿到二维码 PNG、状态和脱敏结果，不拿 Cookie、密码、验证码或私信全文。
- 局域网 HTTP 仅用于可信家庭/个人 Wi‑Fi；不要做公网端口映射。
- 云端使用 `deploy/compose.yaml`，端口默认仅监听服务器回环地址，外部访问必须加 HTTPS 反向代理或私有 VPN。

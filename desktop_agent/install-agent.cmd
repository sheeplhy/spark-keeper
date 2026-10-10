@echo off
chcp 65001 >nul
title 火花管家 - 安装电脑 Agent
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-windows.ps1"
if errorlevel 1 (
  echo.
  echo 安装失败。请确认已安装 Python 3.11 或更高版本，并检查网络连接。
  pause
  exit /b 1
)
echo.
echo 安装完成。现在可以双击 run-agent.cmd 启动。
pause

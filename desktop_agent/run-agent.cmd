@echo off
chcp 65001 >nul
title 火花管家 - 电脑 Agent
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-agent.ps1"
if errorlevel 1 pause

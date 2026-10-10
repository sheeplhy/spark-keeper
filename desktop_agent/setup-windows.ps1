$ErrorActionPreference = "Stop"

$agentRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$venvPython = Join-Path $agentRoot ".venv\Scripts\python.exe"
$requirements = Join-Path $agentRoot "engine\requirements.txt"

if (-not (Test-Path -LiteralPath $venvPython)) {
    py -3 -m venv (Join-Path $agentRoot ".venv")
}

& $venvPython -m pip install --upgrade pip
& $venvPython -m pip install -r $requirements
& $venvPython -m playwright install chromium

Write-Host "安装完成。接下来双击或运行 desktop_agent\start-agent.ps1"

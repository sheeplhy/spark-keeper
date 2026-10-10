$ErrorActionPreference = "Stop"

$agentRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$venvPython = Join-Path $agentRoot ".venv\Scripts\python.exe"
$bridge = Join-Path $agentRoot "bridge.py"

if (-not (Test-Path -LiteralPath $venvPython)) {
    Write-Host "尚未安装电脑 Agent，请先运行 setup-windows.ps1" -ForegroundColor Yellow
    Read-Host "按 Enter 关闭"
    exit 1
}

& $venvPython $bridge

# Smoke check every task must pass. Windows counterpart of smoke.sh: copy to
# scripts/smoke.ps1 in your project and fill in the three commands. Exits
# non-zero on any failure or on more ERROR lines than the baseline allows.
# Works in Windows PowerShell 5.1 and PowerShell 7+.
$ErrorActionPreference = 'Stop'

function Get-Setting($name, $default) {
  $value = [Environment]::GetEnvironmentVariable($name)
  if ($value) { $value } else { $default }
}

$BuildCmd    = Get-Setting 'BUILD_CMD'    "Write-Output 'BUILD_CMD not set'; exit 1"    # e.g. dotnet build -c Release
$TestCmd     = Get-Setting 'TEST_CMD'     "Write-Output 'TEST_CMD not set'; exit 1"     # e.g. dotnet test
$ScenarioCmd = Get-Setting 'SCENARIO_CMD' "Write-Output 'SCENARIO_CMD not set'; exit 1" # a short real run, e.g. .\bin\server.exe --run-for 60s
$MaxErrors   = [int](Get-Setting 'MAX_ERRORS' '0')                                      # baseline from SPEC.md

$logDir = Get-Setting 'SMOKE_LOG_DIR' '.smoke'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

# Each command runs in a child PowerShell (the same one running this script),
# so the step fails on a non-zero exit code or a failed last command.
$shell = (Get-Process -Id $PID).Path

function Step($name, $cmd) {
  Write-Output "== $name"
  $log = Join-Path $logDir "$name.log"
  $ErrorActionPreference = 'Continue'
  & $shell -NoProfile -Command $cmd 2>&1 | Out-File -FilePath $log -Encoding utf8
  if ($LASTEXITCODE -ne 0) {
    Write-Output "FAIL: $name (see $log)"
    Get-Content $log -Tail 20
    exit 1
  }
}

Step 'build' $BuildCmd
Step 'test' $TestCmd
Step 'scenario' $ScenarioCmd

$errors = @(Select-String -Path (Join-Path $logDir '*.log') -Pattern 'ERROR' -CaseSensitive).Count
Write-Output "ERROR lines: $errors (max $MaxErrors)"
if ($errors -gt $MaxErrors) {
  Write-Output 'FAIL: ERROR lines above baseline'
  exit 1
}
Write-Output 'smoke OK'

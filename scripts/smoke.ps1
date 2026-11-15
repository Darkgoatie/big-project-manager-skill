# smoke: build, test, run one short real scenario, count ERROR lines.
# PowerShell twin of smoke.sh, for running by hand on Windows. `git bpm review`
# always runs scripts/smoke.sh, so keep the commands in both files the same.
# Writes .smoke/result.txt ("name value" lines) in the same format.
#
# Exit codes: 0 pass, 1 build failed, 2 tests failed, 3 scenario failed,
#             4 ERROR lines above the allowed count.

param(
    [string]$BuildCmd    = "echo 'TODO: build command'",
    [string]$TestCmd     = "echo 'TODO: test command'",
    [string]$ScenarioCmd = "echo 'TODO: short real scenario'",
    [int]$MaxErrors      = 0,
    [string]$ErrorPattern = "ERROR",
    [string[]]$ExtraLogs = @(),   # extra runtime logs the scenario writes
    [string]$PassRegex   = '(\d+) (passed|passing)',
    [string]$FailRegex   = '(\d+) (failed|failing)',
    [string]$Out         = ".smoke"
)

New-Item -ItemType Directory -Force -Path $Out | Out-Null

function Invoke-Step([string]$cmd, [string]$log) {
    $global:LASTEXITCODE = 0
    $output = & ([scriptblock]::Create($cmd)) 2>&1
    $rc = if ($?) { 0 } else { 1 }
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { $rc = $LASTEXITCODE }
    $output | Out-File -FilePath $log -Encoding utf8
    return $rc
}

function Get-Count([string]$log, [string]$regex) {
    $sum = 0
    foreach ($m in (Select-String -Path $log -Pattern $regex -AllMatches).Matches) { $sum += [int]$m.Groups[1].Value }
    return $sum
}

$sw = [Diagnostics.Stopwatch]::StartNew()
$buildRc = Invoke-Step $BuildCmd "$Out/build.log"
$buildS = [int]$sw.Elapsed.TotalSeconds
if ($buildRc -ne 0) { Write-Output "smoke: build FAILED (see $Out/build.log)"; exit 1 }

$testRc = Invoke-Step $TestCmd "$Out/test.log"
$passed = Get-Count "$Out/test.log" $PassRegex
$failed = Get-Count "$Out/test.log" $FailRegex
$scenRc = Invoke-Step $ScenarioCmd "$Out/scenario.log"

$logs = @("$Out/scenario.log") + ($ExtraLogs | Where-Object { Test-Path $_ })
$errors = @(Select-String -Path $logs -Pattern $ErrorPattern -SimpleMatch).Count

$lines = @(
    "build_s $buildS", "tests_rc $testRc", "tests_passed $passed", "tests_failed $failed",
    "scenario_rc $scenRc", "error_lines $errors"
)
foreach ($m in (Select-String -Path "$Out/scenario.log" -Pattern '^METRIC\s+([\w.-]+)\s+(-?[\d.]+)')) {
    $lines += "$($m.Matches[0].Groups[1].Value) $($m.Matches[0].Groups[2].Value)"
}
[System.IO.File]::WriteAllLines((Join-Path (Resolve-Path $Out) 'result.txt'), $lines)

Write-Output "smoke: build=${buildS}s tests=$passed passed $failed failed (rc $testRc) scenario_rc=$scenRc error_lines=$errors (max $MaxErrors)"

if ($testRc -ne 0) { Write-Output "smoke: tests FAILED (see $Out/test.log)"; exit 2 }
if ($scenRc -ne 0) { Write-Output "smoke: scenario FAILED (see $Out/scenario.log)"; exit 3 }
if ($errors -gt $MaxErrors) { Write-Output "smoke: too many ERROR lines"; exit 4 }
Write-Output "smoke: PASS"

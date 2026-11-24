[CmdletBinding()]
param(
    [switch]$Docker,
    [Alias('w')]
    [switch]$Wsl
)

$projectRoot = Split-Path -Parent $PSScriptRoot
$aiDir = Join-Path $projectRoot "ai"
$ollamaPidFile = Join-Path $aiDir "ollama.pid"
$backendPidFile = Join-Path $aiDir "backend.pid"

function Stop-PidFile {
    param([string]$PidFile, [string]$Label)
    if (-not (Test-Path $PidFile)) { return }
    $pidText = (Get-Content $PidFile -ErrorAction SilentlyContinue | Select-Object -First 1)
    if ($pidText -and ($pidText -match '^\d+$')) {
        $targetPid = [int]$pidText
        $proc = Get-Process -Id $targetPid -ErrorAction SilentlyContinue
        if ($proc) {
            Stop-Process -Id $targetPid -Force -ErrorAction SilentlyContinue
            Write-Host "[EnviVN] Stopped $Label (PID: $targetPid)." -ForegroundColor Green
        }
    }
    Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
}

function Stop-ProjectProcesses {
    # Stop tracked PID files first
    Stop-PidFile -PidFile $backendPidFile -Label "Backend"
    Stop-PidFile -PidFile $ollamaPidFile -Label "Ollama"
    # Clean up any remaining process launched from this project folder
    $localOllamaExe = Join-Path $aiDir "ollama\ollama.exe"
    $localBackendExe = Join-Path $projectRoot "backend\target\release\envivn-backend.exe"
    Get-Process -Name "envivn-backend", "ollama" -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            if ($_.Path -eq $localOllamaExe -or $_.Path -eq $localBackendExe) {
                Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
                Write-Host "[EnviVN] Stopped $($_.ProcessName) (PID: $($_.Id))." -ForegroundColor Green
            }
        } catch {}
    }
}

function Stop-DockerServices {
    $null = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[EnviVN] Docker daemon is not running. Nothing to stop." -ForegroundColor Yellow
        return
    }
    Write-Host "[EnviVN] Stopping Docker backend services..." -ForegroundColor Cyan
    docker compose down
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[EnviVN] Docker backend services stopped successfully." -ForegroundColor Green
    }
}

Set-Location $projectRoot

if ($Docker) {
    Stop-DockerServices
} else {
    Stop-ProjectProcesses
}

if ($Wsl) {
    Write-Host "[EnviVN] Shutting down WSL 2 to release RAM..." -ForegroundColor Cyan
    wsl --shutdown
    Write-Host "[EnviVN] WSL 2 has been shut down." -ForegroundColor Green
}

[CmdletBinding()]
param(
    [Alias('d')]
    [switch]$Detach,
    [string]$Model = "qwen2.5:3b",
    [switch]$Docker,
    [switch]$Build
)

$ErrorActionPreference = "Continue"
$projectRoot = Split-Path -Parent $PSScriptRoot
$aiDir = Join-Path $projectRoot "ai"
$ollamaDir = Join-Path $aiDir "ollama"
$modelsDir = Join-Path $aiDir "models"
$ollamaExe = Join-Path $ollamaDir "ollama.exe"
$ollamaPidFile = Join-Path $aiDir "ollama.pid"
$backendPidFile = Join-Path $aiDir "backend.pid"
$ollamaLogOut = Join-Path $aiDir "ollama.out.log"
$ollamaLogErr = Join-Path $aiDir "ollama.err.log"
$backendLogOut = Join-Path $aiDir "backend.out.log"
$backendLogErr = Join-Path $aiDir "backend.err.log"
$ollamaHost = "127.0.0.1:11434"
$ollamaBaseUrl = "http://$ollamaHost"
$ollamaZipUrl = "https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64.zip"

function Test-TcpPort {
    param([string]$TargetHost, [int]$Port, [int]$TimeoutMs = 200)
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $iar = $client.BeginConnect($TargetHost, $Port, $null, $null)
        if (-not $iar.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) { return $false }
        $client.EndConnect($iar)
        return $true
    } catch {
        return $false
    } finally {
        $client.Dispose()
    }
}

function Test-OllamaReady {
    try {
        $null = Invoke-RestMethod -Uri "$ollamaBaseUrl/api/tags" -TimeoutSec 2
        return $true
    } catch {
        return $false
    }
}

function Ensure-Cargo {
    if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
        $defaultCargoBin = Join-Path $env:USERPROFILE ".cargo\bin"
        if (Test-Path (Join-Path $defaultCargoBin "cargo.exe")) {
            $env:PATH = "$defaultCargoBin;$env:PATH"
        } else {
            Write-Error "Rust/Cargo is not installed. Install it from https://rustup.rs and retry."
            exit 1
        }
    }
}

function Ensure-LocalOllama {
    # Ensure local AI directories exist
    New-Item -ItemType Directory -Path $ollamaDir -Force | Out-Null
    New-Item -ItemType Directory -Path $modelsDir -Force | Out-Null
    if (Test-Path $ollamaExe) {
        Write-Host "[EnviVN] Local Ollama found: $ollamaExe" -ForegroundColor Green
        return
    }
    $zipPath = Join-Path $aiDir "ollama-windows-amd64.zip"
    Write-Host "[EnviVN] Local Ollama not found. Downloading Windows portable package (~1.6 GB)..." -ForegroundColor Yellow
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        & curl.exe -L -C - --fail --retry 3 --retry-delay 2 --progress-bar -o $zipPath $ollamaZipUrl
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to download Ollama from $ollamaZipUrl"
            exit 1
        }
    } else {
        Invoke-WebRequest -Uri $ollamaZipUrl -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
    }
    Write-Host "[EnviVN] Extracting Ollama into $ollamaDir ..." -ForegroundColor Cyan
    if (Get-Command tar.exe -ErrorAction SilentlyContinue) {
        & tar.exe -xf $zipPath -C $ollamaDir
        if ($LASTEXITCODE -ne 0) {
            Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
            Write-Error "Failed to extract $zipPath"
            exit 1
        }
    } else {
        Expand-Archive -Path $zipPath -DestinationPath $ollamaDir -Force
    }
    if (-not (Test-Path $ollamaExe)) {
        Write-Error "Extraction succeeded but ollama.exe was not found in $ollamaDir"
        exit 1
    }
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    Write-Host "[EnviVN] Local Ollama installed successfully." -ForegroundColor Green
}

function Ensure-OllamaServer {
    $env:OLLAMA_MODELS = $modelsDir
    $env:OLLAMA_HOST = $ollamaHost
    if (Test-OllamaReady) {
        Write-Host "[EnviVN] Ollama server is already running at $ollamaBaseUrl." -ForegroundColor Green
        return
    }
    Write-Host "[EnviVN] Starting local Ollama server (models dir: $modelsDir)..." -ForegroundColor Cyan
    $proc = Start-Process -FilePath $ollamaExe -ArgumentList "serve" -WorkingDirectory $ollamaDir -WindowStyle Hidden -RedirectStandardOutput $ollamaLogOut -RedirectStandardError $ollamaLogErr -PassThru
    Set-Content -Path $ollamaPidFile -Value $proc.Id -Encoding Ascii
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Milliseconds 500
        if (Test-OllamaReady) {
            Write-Host "[EnviVN] Ollama server is ready (PID: $($proc.Id))." -ForegroundColor Green
            return
        }
    }
    Write-Error "Timed out waiting for Ollama server. Check logs in $ollamaLogErr"
    exit 1
}

function Ensure-AiModel {
    param([string]$ModelName)
    $tags = Invoke-RestMethod -Uri "$ollamaBaseUrl/api/tags" -TimeoutSec 5
    $installed = $false
    if ($tags.models) {
        foreach ($m in $tags.models) {
            if ($m.name -eq $ModelName -or $m.name -eq "${ModelName}:latest") {
                $installed = $true
                break
            }
        }
    }
    if ($installed) {
        Write-Host "[EnviVN] AI model '$ModelName' is already available." -ForegroundColor Green
        return
    }
    Write-Host "[EnviVN] Pulling AI model '$ModelName' into $modelsDir ..." -ForegroundColor Yellow
    & $ollamaExe pull $ModelName
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to pull AI model '$ModelName'."
        exit 1
    }
    Write-Host "[EnviVN] AI model '$ModelName' is ready." -ForegroundColor Green
}

function Start-DockerStack {
    $null = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[EnviVN] Docker daemon is offline. Starting Docker Desktop..." -ForegroundColor Yellow
        $dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
        if (-not (Test-Path $dockerPath)) {
            Write-Error "Docker Desktop executable not found at '$dockerPath'."
            exit 1
        }
        Start-Process -FilePath $dockerPath
        for ($i = 0; $i -lt 30; $i++) {
            Start-Sleep -Seconds 3
            $null = docker info 2>&1
            if ($LASTEXITCODE -eq 0) { break }
        }
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Timeout while waiting for Docker daemon."
            exit 1
        }
    }
    $composeArgs = @("compose", "up")
    if ($Build) { $composeArgs += "--build" }
    if ($Detach) { $composeArgs += "-d" }
    docker @composeArgs
}

Set-Location $projectRoot

if ($Docker) {
    Start-DockerStack
    exit $LASTEXITCODE
}

# Native Windows mode (default)
Ensure-Cargo
Ensure-LocalOllama
Ensure-OllamaServer
Ensure-AiModel -ModelName $Model

$backendDir = Join-Path $projectRoot "backend"
$backendExe = Join-Path $backendDir "target\release\envivn-backend.exe"

Write-Host "[EnviVN] Building Rust backend (release)..." -ForegroundColor Cyan
Push-Location $backendDir
try {
    & cargo build --release
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build Rust backend."
        exit 1
    }
} finally {
    Pop-Location
}

$env:PORT = if ($env:PORT) { $env:PORT } else { "8080" }
$env:OLLAMA_BASE_URL = $ollamaBaseUrl
$env:AI_MODEL_NAME = $Model
$env:RUST_LOG = if ($env:RUST_LOG) { $env:RUST_LOG } else { "info" }

if (Test-TcpPort -TargetHost "127.0.0.1" -Port 6379) {
    $env:REDIS_HOST = "127.0.0.1"
    $env:REDIS_PORT = "6379"
    Write-Host "[EnviVN] Local Redis detected on 127.0.0.1:6379 (cache enabled)." -ForegroundColor Green
} else {
    $env:REDIS_HOST = "disabled"
    Write-Host "[EnviVN] Redis not running on localhost:6379 (running without cache)." -ForegroundColor Yellow
}

if ($Detach) {
    if (Test-Path $backendPidFile) {
        $oldPid = (Get-Content $backendPidFile -ErrorAction SilentlyContinue | Select-Object -First 1)
        if ($oldPid) { Stop-Process -Id $oldPid -Force -ErrorAction SilentlyContinue }
    }
    Write-Host "[EnviVN] Starting backend in background..." -ForegroundColor Cyan
    $beProc = Start-Process -FilePath $backendExe -WorkingDirectory $backendDir -WindowStyle Hidden -RedirectStandardOutput $backendLogOut -RedirectStandardError $backendLogErr -PassThru
    Set-Content -Path $backendPidFile -Value $beProc.Id -Encoding Ascii
    $beReady = $false
    for ($i = 0; $i -lt 20; $i++) {
        Start-Sleep -Milliseconds 400
        try {
            $health = Invoke-RestMethod -Uri "http://127.0.0.1:$($env:PORT)/api/v1/health" -TimeoutSec 2
            $beReady = $true
            break
        } catch {}
    }
    if (-not $beReady) {
        Write-Error "Backend failed to start. Check logs at $backendLogErr"
        exit 1
    }
    Write-Host "[EnviVN] Backend is running in background (PID: $($beProc.Id))." -ForegroundColor Green
    Write-Host ""
    Write-Host "Services (Native Windows):" -ForegroundColor Yellow
    Write-Host " - Backend API : http://localhost:$($env:PORT)"
    Write-Host " - Health check: http://localhost:$($env:PORT)/api/v1/health"
    Write-Host " - Ollama AI   : $ollamaBaseUrl (model: $Model)"
    Write-Host " - AI Storage  : $aiDir"
    Write-Host ""
    Write-Host "Useful commands:" -ForegroundColor Yellow
    Write-Host " - View BE logs: Get-Content .\ai\backend.out.log -Wait"
    Write-Host " - Stop stack  : .\scripts\be-stop.ps1"
} else {
    Write-Host "[EnviVN] Starting backend on http://localhost:$($env:PORT) (Press Ctrl+C to stop BE)..." -ForegroundColor Cyan
    Write-Host "[EnviVN] Tip: Run .\scripts\be-stop.ps1 later to stop Ollama and release RAM." -ForegroundColor DarkGray
    & $backendExe
}

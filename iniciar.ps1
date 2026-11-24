$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$contratoDir = Join-Path $root "contrato"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   ApuestasPro - Iniciando plataforma     " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Instalar dependencias si faltan
if (-not (Test-Path (Join-Path $contratoDir "node_modules"))) {
    Write-Host "[1/4] Instalando dependencias de Hardhat..." -ForegroundColor Yellow
    Push-Location $contratoDir
    npm install
    Pop-Location
}

# 2. Iniciar nodo Hardhat en segundo plano (si 8545 esta libre)
$hardhatProc = $null
$port8545Open = $false
try {
    $tcp = New-Object System.Net.Sockets.TcpClient("127.0.0.1", 8545)
    $tcp.Close()
    $port8545Open = $true
} catch {}

if (-not $port8545Open) {
    Write-Host "[2/4] Iniciando nodo local de Hardhat (puerto 8545)..." -ForegroundColor Yellow
    $hardhatProc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c npx hardhat node" -WorkingDirectory $contratoDir -WindowStyle Minimized -PassThru

    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Milliseconds 500
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient("127.0.0.1", 8545)
            $tcp.Close()
            $port8545Open = $true
            break
        } catch {}
    }
    if (-not $port8545Open) {
        Write-Host "Error: el nodo Hardhat no respondio a tiempo." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[2/4] Nodo Hardhat ya estaba activo en puerto 8545." -ForegroundColor Green
}

# 3. Desplegar contrato si se acaba de iniciar el nodo
if ($hardhatProc -ne $null) {
    Write-Host "[3/4] Desplegando contrato ApuestasPro..." -ForegroundColor Yellow
    $depDir = Join-Path $contratoDir "ignition\deployments\chain-31337"
    if (Test-Path $depDir) {
        Remove-Item -Recurse -Force $depDir
    }
    Push-Location $contratoDir
    npx hardhat ignition deploy ./ignition/modules/Apuestas.js --network localhost
    Pop-Location
} else {
    Write-Host "[3/4] Contrato ya desplegado en el nodo activo." -ForegroundColor Green
}

# 4. Iniciar servidor web en segundo plano (si 5500 esta libre)
$httpProc = $null
$port5500Open = $false
try {
    $tcp = New-Object System.Net.Sockets.TcpClient("127.0.0.1", 5500)
    $tcp.Close()
    $port5500Open = $true
} catch {}

if (-not $port5500Open) {
    Write-Host "[4/4] Iniciando servidor web en http://localhost:5500 ..." -ForegroundColor Yellow
    $httpProc = Start-Process -FilePath "python" -ArgumentList "-m http.server 5500" -WorkingDirectory $root -WindowStyle Minimized -PassThru
    Start-Sleep -Milliseconds 700
} else {
    Write-Host "[4/4] Servidor web ya estaba activo en puerto 5500." -ForegroundColor Green
}

Write-Host ""
Write-Host "Todo listo. Abriendo http://localhost:5500 ..." -ForegroundColor Green
Start-Process "http://localhost:5500"

Write-Host ""
Write-Host "Presiona ENTER cuando quieras detener los servidores iniciados por este script." -ForegroundColor Cyan
[void][System.Console]::ReadLine()

if ($httpProc -and -not $httpProc.HasExited) {
    cmd /c "taskkill /T /F /PID $($httpProc.Id) >nul 2>&1"
}
if ($hardhatProc -and -not $hardhatProc.HasExited) {
    cmd /c "taskkill /T /F /PID $($hardhatProc.Id) >nul 2>&1"
}
Write-Host "Servidores detenidos." -ForegroundColor Yellow

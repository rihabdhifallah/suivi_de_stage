# Script: start-dev.ps1
# Kills any process using port 3001, then starts the NestJS dev server

$port = 3001
$connections = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
if ($connections) {
    foreach ($conn in $connections) {
        $pid = $conn.OwningProcess
        if ($pid -and $pid -ne 0) {
            Write-Host "Killing process $pid on port $port..."
            Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
        }
    }
    Start-Sleep -Seconds 1
    Write-Host "Port $port freed."
} else {
    Write-Host "Port $port is already free."
}

Write-Host "Starting NestJS dev server..."
npx nodemon

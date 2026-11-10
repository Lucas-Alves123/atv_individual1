# Script para subir o servidor SAM localmente com warm containers
$sam = if (Get-Command sam -ErrorAction SilentlyContinue) { "sam" } elseif (Test-Path "C:\Program Files\Amazon\AWSSAMCLI\bin\sam.cmd") { "C:\Program Files\Amazon\AWSSAMCLI\bin\sam.cmd" } else { "sam" }

Write-Host "Iniciando API local em http://127.0.0.1:3000..." -ForegroundColor Green
& $sam local start-api --warm-containers LAZY


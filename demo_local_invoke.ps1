# Script para demonstrar Invocação por Evento (Passo 3)
$sam = if (Get-Command sam -ErrorAction SilentlyContinue) { "sam" } elseif (Test-Path "C:\Program Files\Amazon\AWSSAMCLI\bin\sam.cmd") { "C:\Program Files\Amazon\AWSSAMCLI\bin\sam.cmd" } else { "sam" }

Write-Host "=== 1. Primeira Invocacao (Cold Start) ===" -ForegroundColor Cyan
& $sam local invoke -e events/pedido.json

Write-Host "`n=== 2. Segunda Invocacao (Warm Start) ===" -ForegroundColor Cyan
& $sam local invoke -e events/pedido.json

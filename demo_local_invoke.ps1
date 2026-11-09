# Script para demonstrar Invocação por Evento (Passo 3)
Write-Host "=== 1. Primeira Invocacao (Cold Start) ===" -ForegroundColor Cyan
& sam local invoke -e events/pedido.json

Write-Host "`n=== 2. Segunda Invocacao (Warm Start) ===" -ForegroundColor Cyan
& sam local invoke -e events/pedido.json


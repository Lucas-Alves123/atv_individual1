# Script para demonstrar chamadas HTTP (Passo 4)
Write-Host "Realizando 3 chamadas HTTP para http://127.0.0.1:3000/guias..." -ForegroundColor Cyan

1..3 | ForEach-Object {
    Write-Host "`n--- Chamada $_ ---" -ForegroundColor Yellow
    $res = Invoke-RestMethod -Uri "http://127.0.0.1:3000/guias" `
        -Method POST `
        -ContentType "application/json" `
        -Body '{"requisicaoId":"R-002","hospital":"H-Caruaru"}'
    
    $res | ConvertTo-Json -Compress
}


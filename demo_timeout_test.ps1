# Script para demonstrar limite de tempo / timeout (Passo 5)
Write-Host "Enviando requisicao com demorar: true para testar timeout..." -ForegroundColor Cyan

try {
    $res = Invoke-RestMethod -Uri "http://127.0.0.1:3000/guias" `
        -Method POST `
        -ContentType "application/json" `
        -Body '{"requisicaoId":"R-003","demorar":true}' `
        -TimeoutSec 15
    
    Write-Host "Sucesso (Timeout configurado suficiente):" -ForegroundColor Green
    $res | ConvertTo-Json -Compress
} catch {
    Write-Host "Erro recebido (Timeout estourado no servidor):" -ForegroundColor Red
    Write-Host "Status HTTP:" $_.Exception.Response.StatusCode.value__
    Write-Host "Mensagem:" $_.Exception.Message
}

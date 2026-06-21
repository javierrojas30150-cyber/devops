# Script para obtener la URL del Frontend desde el LoadBalancer

param(
    [int]$Timeout = 300
)

$ErrorActionPreference = "Stop"

function Write-Status {
    param([string]$Message, [string]$Color = "Green")
    Write-Host $Message -ForegroundColor $Color
}

Write-Status "📦 Esperando que el LoadBalancer asigne una dirección IP pública..." "Yellow"

$elapsed = 0
while ($elapsed -lt $Timeout) {
    try {
        $svc = kubectl get svc frontend-despacho -o json | ConvertFrom-Json
        $externalIP = $svc.status.loadBalancer.ingress[0].hostname
        
        if ($externalIP) {
            Write-Status "✓ LoadBalancer tiene IP asignada" "Green"
            Write-Host "═══════════════════════════════════════" -ForegroundColor Green
            Write-Status "URL del Frontend:" "Green"
            Write-Host "http://$externalIP" -ForegroundColor Yellow
            Write-Host "═══════════════════════════════════════" -ForegroundColor Green
            
            # Guardar la URL en un archivo
            @"
FRONTEND_URL=http://$externalIP
FRONTEND_HOSTNAME=$externalIP
"@ | Out-File -FilePath "frontend-url.txt" -Encoding UTF8
            
            exit 0
        }
    }
    catch {
        # Ignorar errores temporales
    }
    
    Write-Status "Intentando... ($elapsed/$Timeout segundos)" "Yellow"
    Start-Sleep -Seconds 10
    $elapsed += 10
}

Write-Status "✗ Timeout esperando por IP pública del LoadBalancer" "Red"
Write-Status "Intenta ejecutar: kubectl get svc frontend-despacho -w" "Red"
exit 1

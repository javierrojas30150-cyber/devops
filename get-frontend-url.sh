#!/bin/bash

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}📦 Desplegando cambios de Kubernetes...${NC}"

# Aplicar los manifiestos actualizados
kubectl apply -f infra/k8s/frontend.yml
echo -e "${GREEN}✓ Frontend desplegado${NC}"

# Esperar a que el LoadBalancer asigne una IP pública
echo -e "${YELLOW}⏳ Esperando que el LoadBalancer asigne una dirección IP pública...${NC}"

TIMEOUT=300
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    EXTERNAL_IP=$(kubectl get svc frontend-despacho -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    
    if [ ! -z "$EXTERNAL_IP" ]; then
        echo -e "${GREEN}✓ LoadBalancer tiene IP asignada${NC}"
        echo -e "${GREEN}═══════════════════════════════════════${NC}"
        echo -e "${GREEN}URL del Frontend:${NC}"
        echo -e "${YELLOW}http://$EXTERNAL_IP${NC}"
        echo -e "${GREEN}═══════════════════════════════════════${NC}"
        
        # Guardar la URL en un archivo para usar en otros pasos
        echo "FRONTEND_URL=http://$EXTERNAL_IP" > frontend-url.txt
        echo "FRONTEND_HOSTNAME=$EXTERNAL_IP" >> frontend-url.txt
        
        exit 0
    fi
    
    echo -e "${YELLOW}Intentando... ($ELAPSED/$TIMEOUT segundos)${NC}"
    sleep 10
    ELAPSED=$((ELAPSED + 10))
done

echo -e "${RED}✗ Timeout esperando por IP pública del LoadBalancer${NC}"
echo -e "${RED}Intenta ejecutar: kubectl get svc frontend-despacho -w${NC}"
exit 1

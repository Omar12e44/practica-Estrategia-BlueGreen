#!/bin/bash

# Script de despliegue Blue-Green
set -e

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Variables de configuración
APP_NAME="app"
DOCKER_IMAGE=${DOCKER_IMAGE:-"tu-usuario/blue-green-api:latest"}
BLUE_PORT=3001
GREEN_PORT=3002
CONTAINER_PORT=3000

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Despliegue Blue-Green${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Determinar el color activo actual
ACTIVE_COLOR=$(docker ps --filter "name=${APP_NAME}-" --format "{{.Names}}" | grep -o 'blue\|green' | head -n1)

if [ -z "$ACTIVE_COLOR" ]; then
    echo -e "${YELLOW}No hay entorno activo. Iniciando en BLUE${NC}"
    TARGET_COLOR="blue"
    TARGET_PORT=$BLUE_PORT
else
    echo -e "${GREEN}Entorno activo actual: ${ACTIVE_COLOR}${NC}"
    if [ "$ACTIVE_COLOR" = "blue" ]; then
        TARGET_COLOR="green"
        TARGET_PORT=$GREEN_PORT
    else
        TARGET_COLOR="blue"
        TARGET_PORT=$BLUE_PORT
    fi
fi

echo -e "${GREEN}Desplegando en: ${TARGET_COLOR}${NC}"
echo -e "${GREEN}Puerto: ${TARGET_PORT}${NC}"
echo ""

# Hacer 'docker pull' de la nueva imagen
echo -e "${YELLOW}Haciendo 'docker pull' de la nueva imagen...${NC}"
docker pull $DOCKER_IMAGE

# Limpiar contenedor inactivo anterior si existe
echo -e "${YELLOW}Limpiando contenedor inactivo anterior 'app-${TARGET_COLOR}'...${NC}"
docker stop "app-${TARGET_COLOR}" 2>/dev/null || true
docker rm "app-${TARGET_COLOR}" 2>/dev/null || true

# Iniciar nuevo contenedor
echo -e "${YELLOW}Iniciando nuevo contenedor 'app-${TARGET_COLOR}' en puerto ${TARGET_PORT}...${NC}"
docker run -d \
    --name "app-${TARGET_COLOR}" \
    -p ${TARGET_PORT}:${CONTAINER_PORT} \
    -e PORT=${CONTAINER_PORT} \
    -e APP_COLOR=${TARGET_COLOR} \
    --restart always \
    $DOCKER_IMAGE

# Esperar a que el contenedor inicie
echo -e "${YELLOW}Esperando 10s para que el contenedor inicie...${NC}"
sleep 10

# Verificar health check
echo -e "${YELLOW}Ejecutando Smoke Test en http://127.0.0.1:${TARGET_PORT}...${NC}"
if ! curl --fail --silent --show-error http://127.0.0.1:${TARGET_PORT}/health > /dev/null; then
    echo -e "${RED}********************************************${NC}"
    echo -e "${RED}¡ERROR! El Smoke Test falló para 'app-${TARGET_COLOR}'.${NC}"
    echo -e "${RED}Despliegue cancelado.${NC}"
    echo -e "${RED}********************************************${NC}"
    
    # Rollback: detener y eliminar el contenedor fallido
    docker stop "app-${TARGET_COLOR}" || true
    docker rm "app-${TARGET_COLOR}" || true
    exit 1
fi

echo -e "${GREEN}✓ Smoke Test exitoso.${NC}"
echo ""

# Actualizar Nginx para apuntar al nuevo contenedor
echo -e "${YELLOW}Actualizando Nginx para apuntar a ${TARGET_COLOR} (puerto ${TARGET_PORT})...${NC}"

sudo tee /etc/nginx/sites-available/blue-green > /dev/null <<EOF
upstream backend {
    server 127.0.0.1:${TARGET_PORT};
}

server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /health {
        proxy_pass http://backend/health;
        access_log off;
    }
}
EOF

sudo nginx -t && sudo systemctl reload nginx
echo -e "${GREEN}✓ Nginx actualizado${NC}"
echo ""

# Detener el contenedor antiguo (si existe)
if [ ! -z "$ACTIVE_COLOR" ]; then
    echo -e "${YELLOW}Deteniendo contenedor antiguo 'app-${ACTIVE_COLOR}'...${NC}"
    docker stop "app-${ACTIVE_COLOR}" || true
    echo -e "${GREEN}✓ Contenedor ${ACTIVE_COLOR} detenido${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✓ Despliegue completado exitosamente${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Entorno activo: ${TARGET_COLOR}${NC}"
echo -e "${GREEN}Puerto: ${TARGET_PORT}${NC}"
echo ""
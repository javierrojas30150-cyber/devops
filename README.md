# 🚀 Sistema de Gestión de Despachos y Ventas - DevOps

**Arquitectura de microservicios modernos desplegada en AWS EKS con Kubernetes, Spring Boot, React y MySQL**

[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=FF9900)](https://aws.amazon.com/)
[![Spring Boot](https://img.shields.io/badge/Spring_Boot-F2F4F9?style=for-the-badge&logo=spring-boot)](https://spring.io/projects/spring-boot)
[![React](https://img.shields.io/badge/React-61DAFB?style=for-the-badge&logo=react&logoColor=black)](https://reactjs.org/)

---

## 📋 Tabla de Contenidos

- [Descripción del Proyecto](#descripción-del-proyecto)
- [Stack Tecnológico](#stack-tecnológico)
- [Arquitectura](#arquitectura)
- [Requisitos del Sistema](#requisitos-del-sistema)
- [Instalación Rápida](#instalación-rápida)
- [Despliegue Local con Docker Compose](#despliegue-local-con-docker-compose)
- [Despliegue en AWS EKS](#despliegue-en-aws-eks)
- [Autoscaling](#autoscaling)
- [Pipeline CI/CD](#pipeline-cicd)
- [API y Endpoints](#api-y-endpoints)
- [Monitoreo y Logs](#monitoreo-y-logs)
- [Troubleshooting](#troubleshooting)
- [Contribución](#contribución)
- [Licencia](#licencia)

---

## 📝 Descripción del Proyecto

Sistema integral de gestión de **despachos y ventas** implementado como arquitectura de microservicios con:

✅ **Dos backends Spring Boot** independientes (Despachos y Ventas)
✅ **Frontend React moderno** con Vite y Tailwind CSS
✅ **Base de datos MySQL** centralizada
✅ **Orquestación en Kubernetes (EKS)** en AWS
✅ **Autoscaling automático** de pods y nodos
✅ **Pipeline CI/CD** completamente automatizado con GitHub Actions
✅ **Balanceador de carga** ALB de AWS
✅ **Alta disponibilidad** y tolerancia a fallos

### Casos de Uso

- Gestión de despachos de pedidos
- Control de ventas y transacciones
- Seguimiento de estado de pedidos
- Reportes de ventas y despachos

---

## 🔧 Stack Tecnológico

| Capa | Tecnología | Versión | Propósito |
|------|-----------|---------|----------|
| **Frontend** | React + Vite | 18 | UI interactiva |
| **Styling** | Tailwind CSS | v3 | Diseño responsivo |
| **Backend 1** | Spring Boot | 3.4.4 | API Despachos |
| **Backend 2** | Spring Boot | 3.4.4 | API Ventas |
| **API Docs** | Springdoc OpenAPI | 2.x | Swagger/OpenAPI |
| **Base de Datos** | MySQL | 8.0 | Persistencia |
| **Orquestación** | Kubernetes (EKS) | 1.29+ | Container orchestration |
| **Registro** | Amazon ECR | - | Imágenes Docker |
| **Proxy Reverso** | Nginx | latest | Reverse proxy |
| **CI/CD** | GitHub Actions | - | Automatización |
| **Infraestructura** | Terraform | 1.5+ | IaC (opcional) |

---

## 🏗️ Arquitectura

### Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────────────┐
│                      AWS VPC (10.0.0.0/16)                         │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │                    AWS EKS Cluster                            │ │
│  │  ┌─────────────────────────────────────────────────────────┐ │ │
│  │  │                   Control Plane                         │ │ │
│  │  │              (AWS Managed, Highly Available)            │ │ │
│  │  └─────────────────────────────────────────────────────────┘ │ │
│  │                                                               │ │
│  │  ┌─────────────────────────────────────────────────────────┐ │ │
│  │  │                    Worker Nodes (ASG)                  │ │ │
│  │  │              Min: 2 | Max: 4 | Type: t3.medium         │ │ │
│  │  │                                                         │ │ │
│  │  │  ┌────────────────────────────────────────────────┐   │ │ │
│  │  │  │  🌐 Frontend (Nginx)  - LoadBalancer Service │   │ │ │
│  │  │  │  ├─ Pods: 1-3 (HPA)                          │   │ │ │
│  │  │  │  ├─ CPU Limit: 100m | Memory: 128Mi         │   │ │ │
│  │  │  │  └─ Puerto externo: 80                       │   │ │ │
│  │  │  └────────────────────────────────────────────────┘   │ │ │
│  │  │           ↓ (Service Discovery DNS)                   │ │ │
│  │  │  ┌────────────────────────────────────────────────┐   │ │ │
│  │  │  │  📦 Backend Despacho - ClusterIP Service     │   │ │ │
│  │  │  │  ├─ Pods: 2-5 (HPA)                          │   │ │ │
│  │  │  │  ├─ Spring Boot: 8081                        │   │ │ │
│  │  │  │  ├─ CPU Limit: 500m | Memory: 512Mi         │   │ │ │
│  │  │  │  └─ Liveness/Readiness: /actuator/health    │   │ │ │
│  │  │  └────────────────────────────────────────────────┘   │ │ │
│  │  │                                                         │ │ │
│  │  │  ┌────────────────────────────────────────────────┐   │ │ │
│  │  │  │  📦 Backend Ventas - ClusterIP Service       │   │ │ │
│  │  │  │  ├─ Pods: 2-5 (HPA)                          │   │ │ │
│  │  │  │  ├─ Spring Boot: 8080                        │   │ │ │
│  │  │  │  ├─ CPU Limit: 500m | Memory: 512Mi         │   │ │ │
│  │  │  │  └─ Liveness/Readiness: /actuator/health    │   │ │ │
│  │  │  └────────────────────────────────────────────────┘   │ │ │
│  │  │           ↓ (Service Discovery DNS)                   │ │ │
│  │  │  ┌────────────────────────────────────────────────┐   │ │ │
│  │  │  │  🗄️  MySQL - StatefulSet + ClusterIP        │   │ │ │
│  │  │  │  ├─ Pods: 1 (No escalable)                  │   │ │ │
│  │  │  │  ├─ Puerto: 3306                             │   │ │ │
│  │  │  │  ├─ Storage: 20Gi EBS (PersistentVolume)    │   │ │ │
│  │  │  │  └─ Init DB: DatosInicialesDespachos        │   │ │ │
│  │  │  └────────────────────────────────────────────────┘   │ │ │
│  │  └─────────────────────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │              AWS Application Load Balancer (ALB)             │ │
│  │  ├─ Listener: 80 (HTTP) → Frontend Service                 │ │
│  │  ├─ Health Check: /                                         │ │
│  │  └─ URL Pública: http://<ALB-Hostname>                      │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │           Amazon ECR (Elastic Container Registry)            │ │
│  │  ├─ backend-despacho:latest                                 │ │
│  │  ├─ backend-ventas:latest (futuro)                          │ │
│  │  └─ frontend-despacho:latest                                │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                   GitHub & GitHub Actions CI/CD                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Push a rama 'develop' → GitHub Actions Triggered                  │
│       ↓                                                              │
│  1. Checkout código                                                 │
│  2. Configurar AWS credentials                                     │
│  3. Login a Amazon ECR                                             │
│  4. Build & Push Docker Images → ECR                              │
│  5. Configure kubectl (EKS connection)                            │
│  6. Apply Kubernetes manifests                                     │
│  7. Update deployment images                                       │
│  8. Wait for rollout completion                                   │
│  9. Verify services                                                │
│  10. Get Load Balancer URL                                        │
│       ↓                                                              │
│  ✅ Frontend disponible: http://<ALB-Hostname>                     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Flujo de Solicitud HTTP

```
Cliente (Internet)
    ↓ HTTP:80
ALB (Application Load Balancer)
    ↓ :8080 (Service: frontend-despacho)
Pod Nginx (Frontend)
    ↓ /api/despachos → :8081 (Service: backend-despacho)
    ↓ /api/ventas    → :8080 (Service: backend-ventas)
Backend Spring Boot
    ↓
MySQL (Service: mysql:3306)
```

---

## 🔧 Requisitos del Sistema

### Hardware (Para desarrollo local)

| Componente | Mínimo | Recomendado |
|-----------|--------|------------|
| **CPU** | 4 cores | 8 cores |
| **RAM** | 8 GB | 16 GB |
| **Disco** | 50 GB SSD | 100 GB SSD |
| **Conexión** | 5 Mbps | 20 Mbps |

### Software Obligatorio

- **Windows 10/11, macOS 10.14+, o Linux (Ubuntu 20.04+)**
- **Docker Desktop 4.0+** → [Descargar](https://www.docker.com/products/docker-desktop)
- **Git 2.30+** → [Descargar](https://git-scm.com/)
- **AWS CLI v2** → [Instalar](https://aws.amazon.com/cli/)
- **kubectl 1.28+** → [Instalar](https://kubernetes.io/docs/tasks/tools/)
- **Node.js 18+ LTS** (para desarrollo frontend local)
- **Maven 3.8.1+** (para construcción local de Spring Boot)

### Configuración de AWS

Necesitas una cuenta AWS con acceso a:
- EC2 (para nodos)
- EKS (para Kubernetes)
- ECR (para registro de imágenes)
- VPC y subnets
- IAM (roles y políticas)

> 💡 Podés usar **AWS Academy Educate** para obtener créditos gratis

---

## 🚀 Instalación Rápida

### 1️⃣ Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/despachos-devops.git
cd despachos-devops
```

### 2️⃣ Configurar AWS CLI

```bash
# Configurar credenciales (obtén del AWS Academy)
aws configure

# Verifica acceso
aws sts get-caller-identity
```

### 3️⃣ Verificar requisitos

```bash
# Verificar todas las herramientas
docker --version      # Docker Desktop 4.0+
kubectl version       # kubectl 1.28+
aws --version         # AWS CLI 2.0+
git --version         # Git 2.30+
docker-compose --version  # Docker Compose (incluido en Docker Desktop)

# Debe devolver versiones sin errores
```

### 4️⃣ Opción: Despliegue Local (Recomendado primero)

```bash
# Construir imágenes (5-10 minutos)
docker-compose build

# Iniciar servicios
docker-compose up -d

# Esperar a que MySQL se inicie (verificar logs)
docker-compose logs -f mysql

# Abrir navegador a http://localhost:3000
```

### 5️⃣ Opción: Despliegue en AWS EKS

> ⚠️ Avanzado - Requiere configuración AWS previa

```bash
# Ver sección "Despliegue en AWS EKS" más abajo
```

---

## 🐳 Despliegue Local con Docker Compose

### Inicio rápido

```bash
# Construir todas las imágenes
docker-compose build

# Iniciar contenedores en background
docker-compose up -d

# Ver estado
docker-compose ps
```

**Salida esperada:**

```
NAME                 IMAGE                            STATUS       PORTS
mysql                despachos-devops-mysql          Up 1 min     3306/tcp
backend-despacho     despachos-devops-backend-desp   Up 30s       0.0.0.0:8081->8081/tcp
backend-ventas       despachos-devops-backend-venta  Up 20s       0.0.0.0:8080->8080/tcp
frontend-despacho    despachos-devops-frontend       Up 10s       0.0.0.0:3000->8080/tcp
```

### Acceder a las aplicaciones

| Aplicación | URL | Usuario | Contraseña |
|-----------|-----|---------|-----------|
| **Frontend** | http://localhost:3000 | - | - |
| **Backend Despacho (Swagger)** | http://localhost:8081/swagger-ui.html | - | - |
| **Backend Ventas** | http://localhost:8080 | - | - |
| **MySQL** | localhost:3306 | root | root |

### Verificación de salud

```bash
# Backend Despacho
curl http://localhost:8081/actuator/health
# Esperado: {"status":"UP"}

# Backend Ventas
curl http://localhost:8080/actuator/health

# Frontend (página)
curl http://localhost:3000
```

### Ver logs en tiempo real

```bash
# Todos los servicios
docker-compose logs -f

# Solo MySQL
docker-compose logs -f mysql

# Solo backend despacho
docker-compose logs -f backend-despacho

# Ctrl+C para salir
```

### Detener y limpiar

```bash
# Detener contenedores
docker-compose down

# Detener y eliminar volúmenes (elimina datos)
docker-compose down -v

# Reconstruir desde cero
docker-compose build --no-cache
```

### Variables de entorno (.env)

Crear archivo `.env` en raíz del proyecto:

```env
# MySQL
MYSQL_DATABASE=despachos
MYSQL_ROOT_PASSWORD=root
MYSQL_ROOT_HOST=%

# Backend
SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/despachos?allowPublicKeyRetrieval=true&useSSL=false
SPRING_DATASOURCE_USERNAME=root
SPRING_DATASOURCE_PASSWORD=root
SPRING_JPA_HIBERNATE_DDL_AUTO=update
SPRING_JPA_SHOW_SQL=false

# Profiles
SPRING_PROFILES_ACTIVE=dev
```

---

## ☁️ Despliegue en AWS EKS

### PARTE 1: Configuración Inicial

#### Paso 1: Obtener credenciales AWS Academy

1. Acceder a https://awsacademy.instructure.com
2. Ir a "Learner Lab" o "Educate"
3. Hacer click en "Start Lab"
4. Copiar Access Key, Secret Key, Session Token
5. Configurar en máquina local:

```bash
aws configure

# Ingresar valores del paso 3
AWS Access Key ID: [Access Key]
AWS Secret Access Key: [Secret Key]
Default region name: us-east-1
Default output format: json

# Verificar
aws sts get-caller-identity
```

**Output esperado:**
```json
{
    "UserId": "AIDAI...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/voclabs"
}
```

### PARTE 2: Crear Infraestructura

#### Opción A: Usando Scripts Bash (Recomendado)

Ejecutar script de setup:

```bash
./scripts/setup-eks.sh
```

**¿Qué hace?**
- Crea VPC con subnets
- Crea Internet Gateway y rutas
- Crea roles IAM
- Crea EKS cluster
- Crea node group
- Configura kubectl

#### Opción B: Manual (Paso a paso)

##### 2.1 Crear VPC y Subnets

```bash
# Guardar variables
export CLUSTER_NAME="despachos-cluster"
export REGION="us-east-1"
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Crear VPC
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --region $REGION \
  --query 'Vpc.VpcId' \
  --output text)
echo "VPC ID: $VPC_ID"

# Crear subnets públicas
SUBNET_PUBLIC_1=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 \
  --availability-zone ${REGION}a \
  --region $REGION \
  --query 'Subnet.SubnetId' \
  --output text)
echo "Subnet Público 1: $SUBNET_PUBLIC_1"

SUBNET_PUBLIC_2=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.2.0/24 \
  --availability-zone ${REGION}b \
  --region $REGION \
  --query 'Subnet.SubnetId' \
  --output text)
echo "Subnet Público 2: $SUBNET_PUBLIC_2"

# Crear subnets privadas
SUBNET_PRIVATE_1=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.10.0/24 \
  --availability-zone ${REGION}a \
  --region $REGION \
  --query 'Subnet.SubnetId' \
  --output text)
echo "Subnet Privado 1: $SUBNET_PRIVATE_1"

SUBNET_PRIVATE_2=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.11.0/24 \
  --availability-zone ${REGION}b \
  --region $REGION \
  --query 'Subnet.SubnetId' \
  --output text)
echo "Subnet Privado 2: $SUBNET_PRIVATE_2"
```

##### 2.2 Crear Internet Gateway

```bash
# Crear IGW
IGW_ID=$(aws ec2 create-internet-gateway \
  --region $REGION \
  --query 'InternetGateway.InternetGatewayId' \
  --output text)
echo "IGW ID: $IGW_ID"

# Adjuntar a VPC
aws ec2 attach-internet-gateway \
  --vpc-id $VPC_ID \
  --internet-gateway-id $IGW_ID \
  --region $REGION
```

##### 2.3 Configurar rutas

```bash
# Obtener Route Table
ROUTE_TABLE=$(aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --region $REGION \
  --query 'RouteTables[0].RouteTableId' \
  --output text)
echo "Route Table: $ROUTE_TABLE"

# Agregar ruta a Internet
aws ec2 create-route \
  --route-table-id $ROUTE_TABLE \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID \
  --region $REGION
```

##### 2.4 Crear Roles IAM

```bash
# Crear rol para EKS Service
EKS_ROLE=$(aws iam create-role \
  --role-name "${CLUSTER_NAME}-service-role" \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "eks.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }' \
  --query 'Role.Arn' \
  --output text)
echo "EKS Role: $EKS_ROLE"

# Adjuntar políticas
aws iam attach-role-policy \
  --role-name "${CLUSTER_NAME}-service-role" \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSServiceRolePolicy

aws iam attach-role-policy \
  --role-name "${CLUSTER_NAME}-service-role" \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSVPCResourceController

# Crear rol para Nodos
NODE_ROLE=$(aws iam create-role \
  --role-name "${CLUSTER_NAME}-node-role" \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }' \
  --query 'Role.Arn' \
  --output text)
echo "Node Role: $NODE_ROLE"

# Adjuntar políticas
aws iam attach-role-policy \
  --role-name "${CLUSTER_NAME}-node-role" \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

aws iam attach-role-policy \
  --role-name "${CLUSTER_NAME}-node-role" \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy

aws iam attach-role-policy \
  --role-name "${CLUSTER_NAME}-node-role" \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
```

##### 2.5 Crear EKS Cluster

```bash
# Crear cluster (tarda 10-15 minutos)
aws eks create-cluster \
  --name $CLUSTER_NAME \
  --version 1.29 \
  --role-arn $EKS_ROLE \
  --resources-vpc-config \
    "subnetIds=$SUBNET_PUBLIC_1,$SUBNET_PUBLIC_2,$SUBNET_PRIVATE_1,$SUBNET_PRIVATE_2" \
  --region $REGION

# Esperar
echo "Esperando a que EKS Cluster se cree... (10-15 minutos)"
aws eks wait cluster-created \
  --name $CLUSTER_NAME \
  --region $REGION

echo "✅ Cluster creado!"

# Actualizar kubeconfig
aws eks update-kubeconfig \
  --name $CLUSTER_NAME \
  --region $REGION

# Verificar
kubectl get nodes
```

##### 2.6 Crear Node Group

```bash
# Crear nodegroup (tarda 5-10 minutos)
aws eks create-nodegroup \
  --cluster-name $CLUSTER_NAME \
  --nodegroup-name "${CLUSTER_NAME}-nodes" \
  --subnets $SUBNET_PRIVATE_1 $SUBNET_PRIVATE_2 \
  --node-role $NODE_ROLE \
  --scaling-config minSize=2,maxSize=4,desiredSize=2 \
  --instance-types t3.medium \
  --region $REGION

# Esperar
echo "Esperando a que los nodos se creen... (5-10 minutos)"
aws eks wait nodegroup-active \
  --cluster-name $CLUSTER_NAME \
  --nodegroup-name "${CLUSTER_NAME}-nodes" \
  --region $REGION

echo "✅ Nodos creados!"

# Verificar nodos
kubectl get nodes -o wide
```

### PARTE 3: Crear repositorios ECR

```bash
# Login a ECR
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Crear repositorio para backend-despacho
aws ecr create-repository \
  --repository-name backend-despacho \
  --region $REGION

# Crear repositorio para frontend-despacho
aws ecr create-repository \
  --repository-name frontend-despacho \
  --region $REGION

# Crear repositorio para backend-ventas (futuro)
aws ecr create-repository \
  --repository-name backend-ventas \
  --region $REGION

# Listar repositorios
aws ecr describe-repositories --region $REGION
```

### PARTE 4: Construir y pushear imágenes

```bash
# Definir registros
BACKEND_DESPACHO_IMAGE="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/backend-despacho:latest"
FRONTEND_IMAGE="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/frontend-despacho:latest"

# Construir Backend Despacho
docker build -t backend-despacho:latest \
  -t $BACKEND_DESPACHO_IMAGE \
  ./back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO

# Pushear Backend Despacho
docker push $BACKEND_DESPACHO_IMAGE

# Construir Frontend
docker build -t frontend-despacho:latest \
  -t $FRONTEND_IMAGE \
  ./front_despacho

# Pushear Frontend
docker push $FRONTEND_IMAGE

# Verificar en ECR
aws ecr describe-images --repository-name backend-despacho --region $REGION
aws ecr describe-images --repository-name frontend-despacho --region $REGION
```

### PARTE 5: Desplegar en Kubernetes

```bash
# Actualizar manifiestos con tu ACCOUNT_ID
export ACCOUNT_ID_SED=$(echo $ACCOUNT_ID | sed 's/\//\\\//g')

# Linux/macOS
sed -i.bak "s/\${ACCOUNT_ID}/$ACCOUNT_ID/g" infra/k8s/*.yml
sed -i.bak "s/\${REGION}/$REGION/g" infra/k8s/*.yml

# Windows PowerShell
(Get-Content infra/k8s/*.yml) -replace '\$\{ACCOUNT_ID\}', $ACCOUNT_ID | Set-Content infra/k8s/*.yml

# Verificar cambios
grep -l "dkr.ecr" infra/k8s/*.yml

# Aplicar manifiestos
kubectl apply -f infra/k8s/

# Verificar estado (esperar a que todos los pods estén Running)
kubectl get pods -w
kubectl get svc -w

# Obtener URL pública del frontend
FRONTEND_URL=$(kubectl get svc frontend-despacho \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Frontend URL: http://$FRONTEND_URL"

# Si tardó <2 minutos, esperar (ALB necesita tiempo para configurarse)
while [ -z "$FRONTEND_URL" ]; do
  echo "Esperando ALB..."
  sleep 10
  FRONTEND_URL=$(kubectl get svc frontend-despacho \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
done

echo "✅ Sistema listo en: http://$FRONTEND_URL"
```

### Verificar despliegue

```bash
# Ver todos los recursos
kubectl get all

# Ver deployments
kubectl get deployments -o wide

# Ver servicios
kubectl get services -o wide

# Ver pods detallado
kubectl describe pods

# Ver logs de un pod
kubectl logs -f deployment/backend-despacho
kubectl logs -f deployment/frontend-despacho

# Ejecutar test desde dentro del cluster
kubectl run -it --rm debug --image=alpine --restart=Never -- \
  wget -qO- http://frontend-despacho/

# Acceder interactivamente a un pod
kubectl exec -it <POD_NAME> -- /bin/bash
```

---

## 📈 Autoscaling

### Horizontal Pod Autoscaler (HPA)

Los pods se escalan automáticamente según CPU/Memory:

```bash
# Instalar Metrics Server (requerido para HPA)
kubectl apply -f \
  https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Esperar a que esté listo
kubectl wait --for=condition=available --timeout=300s \
  deployment/metrics-server -n kube-system

# Aplicar HPA
kubectl apply -f infra/k8s/hpa.yml

# Ver HPA
kubectl get hpa
kubectl describe hpa backend-despacho-hpa

# Monitorear en tiempo real
watch kubectl get hpa
```

### Configuración actual HPA

| Componente | Min Pods | Max Pods | CPU Target | Memory Target |
|-----------|----------|----------|-----------|---------------|
| Backend Despacho | 2 | 5 | 50% | 70% |
| Frontend | 1 | 3 | 60% | 70% |
| Backend Ventas | 2 | 5 | 50% | 70% |

### Prueba de autoscaling

```bash
# Terminal 1: Ver HPA en tiempo real
watch kubectl get hpa,pods,nodes

# Terminal 2: Generar carga
kubectl run -it --rm load-gen \
  --image=busybox:1.28 \
  --restart=Never \
  -- /bin/sh -c "while true; do wget -q -O- http://backend-despacho:8081/actuator/health; done"

# Esperar 1-2 minutos
# Deberías ver:
# 1. CPU de backend-despacho sube
# 2. HPA crea más pods
# 3. Si faltan recursos, nodos adicionales se crean (ASG)
```

---

## 🔄 Pipeline CI/CD

### Flujo automático

```
Push a 'develop' en GitHub
        ↓
GitHub Actions dispara workflow
        ↓
1. Checkout código
2. Configurar AWS credentials
3. Login a ECR
4. Build Backend → ECR
5. Build Frontend → ECR
6. Actualizar kubeconfig
7. Apply Kubernetes manifests
8. Update images (rolling deployment)
9. Wait for rollout
10. Verify services
11. Get Load Balancer URL
        ↓
✅ Frontend actualizado
```

### Configurar CI/CD

#### Paso 1: Agregar secretos a GitHub

Ir a **Settings** → **Secrets and variables** → **Actions**

Agregar estos secretos:

| Secret | Valor |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | Tu Access Key de AWS Academy |
| `AWS_SECRET_ACCESS_KEY` | Tu Secret Key de AWS Academy |
| `AWS_REGION` | us-east-1 |
| `AWS_ACCOUNT_ID` | Resultado de `aws sts get-caller-identity --query Account` |
| `EKS_CLUSTER_NAME` | despachos-cluster |

#### Paso 2: GitHub Actions ya está configurado

El workflow está en `.github/workflows/ci.yml`

Características:
- Se ejecuta en PUSH a rama `develop`
- Build multi-arquitectura (linux/amd64)
- Automatic tag de imagen: `:latest` y `:git-sha`
- Rolling deployment (0 downtime)

#### Paso 3: Hacer cambios y pushear

```bash
# Crear rama develop si no existe
git checkout -b develop
git push -u origin develop

# Hacer cambios
git add .
git commit -m "feat: Nueva funcionalidad de despachos"

# Pushear
git push origin develop

# GitHub Actions se ejecuta automáticamente
# Ver en: https://github.com/tu-usuario/despachos-devops/actions
```

---

## 🔌 API y Endpoints

### Backend Despacho (Puerto 8081)

**Base URL**: `http://backend-despacho:8081` (interno)

#### Documentación Swagger

Acceder a http://localhost:8081/swagger-ui.html (local)

Endpoints principales:

| Método | Path | Descripción |
|--------|------|------------|
| `GET` | `/api/despachos` | Listar todos despachos |
| `GET` | `/api/despachos/{id}` | Obtener despacho por ID |
| `POST` | `/api/despachos` | Crear nuevo despacho |
| `PUT` | `/api/despachos/{id}` | Actualizar despacho |
| `DELETE` | `/api/despachos/{id}` | Eliminar despacho |
| `GET` | `/actuator/health` | Health check |

### Backend Ventas (Puerto 8080)

**Base URL**: `http://backend-ventas:8080` (interno)

Endpoints principales:

| Método | Path | Descripción |
|--------|------|------------|
| `GET` | `/api/ventas` | Listar ventas |
| `GET` | `/api/ventas/{id}` | Obtener venta |
| `POST` | `/api/ventas` | Crear venta |
| `PUT` | `/api/ventas/{id}` | Actualizar venta |
| `DELETE` | `/api/ventas/{id}` | Eliminar venta |
| `GET` | `/actuator/health` | Health check |

### Frontend (Puerto 3000 local, 80 EKS)

| Ruta | Componente | Descripción |
|------|-----------|------------|
| `/` | Home | Página de inicio |
| `/admin` | CrudAdmin | Panel de administración |
| `/admin/despachos` | TableDespachos | Gestión de despachos |
| `/admin/ventas` | TableVentas | Gestión de ventas |

---

## 📊 Monitoreo y Logs

### Kubernetes Monitoring

```bash
# Ver uso de recursos en tiempo real
kubectl top nodes
kubectl top pods

# Ver eventos del cluster
kubectl get events -w

# Ver logs de un pod
kubectl logs <POD_NAME>
kubectl logs -f <POD_NAME>  # Con -f ver en vivo

# Logs de múltiples pods
kubectl logs -f -l app=backend-despacho

# Ver logs anteriores (si pod reinició)
kubectl logs --previous <POD_NAME>
```

### CloudWatch (AWS)

```bash
# Ver logs de EKS en CloudWatch
aws logs describe-log-groups --region us-east-1

# Ver logs de cluster
aws logs describe-log-streams \
  --log-group-name /aws/eks/despachos-cluster/cluster \
  --region us-east-1

# Ver métricas de CloudWatch
aws cloudwatch get-metric-statistics \
  --namespace AWS/EKS \
  --metric-name ClusterNodeCount \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Average \
  --region us-east-1
```

### Dashboards Dashboard

Ver pods:
```bash
kubectl get pods --all-namespaces -w
```

Ver servicios expuestos:
```bash
kubectl get services
```

Ver PersistentVolumes:
```bash
kubectl get pv
```

---

## 🔧 Troubleshooting

### Problema: Pod stuck en "Pending"

**Causa**: Insuficientes recursos o subnets mal configuradas

```bash
# Verificar
kubectl describe pod <POD_NAME>

# Ver eventos
kubectl get events --sort-by='.lastTimestamp'

# Aumentar nodos
aws eks update-nodegroup-config \
  --cluster-name despachos-cluster \
  --nodegroup-name despachos-nodes \
  --scaling-config minSize=2,maxSize=8,desiredSize=4
```

### Problema: Frontend no conecta a Backend

**Causa**: DNS o NetworkPolicy

```bash
# Verificar DNS dentro del cluster
kubectl run -it --rm debug \
  --image=alpine \
  --restart=Never \
  -- nslookup backend-despacho

# Verificar conectividad
kubectl exec -it <FRONTEND_POD> -- \
  wget -q -O- http://backend-despacho:8081/actuator/health
```

### Problema: MySQL no inicia

**Causa**: Volumen no disponible o permisos

```bash
# Ver logs de MySQL
kubectl logs -f statefulset/mysql

# Ver PVC
kubectl get pvc

# Ver PV
kubectl get pv

# Describir el error
kubectl describe pod mysql-0
```

### Problema: ALB sin IP pública

**Causa**: Timeout de AWS o LoadBalancer no configurado

```bash
# Verificar servicio
kubectl describe svc frontend-despacho

# Puede tardar 5-10 minutos
# Esperar con
watch kubectl get svc frontend-despacho

# Si sigue sin IP después de 10 minutos:
kubectl delete svc frontend-despacho
kubectl apply -f infra/k8s/frontend.yml
```

### Limpiar recursos AWS (⚠️ Peligroso)

```bash
# Eliminar cluster (borra TODO)
aws eks delete-cluster --name despachos-cluster --region us-east-1

# Eliminar nodegroup
aws eks delete-nodegroup \
  --cluster-name despachos-cluster \
  --nodegroup-name despachos-nodes \
  --region us-east-1

# Eliminar VPC, subnets, IGW
# ⚠️ Manual - ir a AWS Console
```

---

## 🤝 Contribución

### Workflow de desarrollo

```bash
# 1. Crear rama de feature
git checkout -b feature/nueva-funcionalidad

# 2. Hacer cambios

# 3. Commit seguindo Conventional Commits
git commit -m "feat: descripción de la feature"
git commit -m "fix: corrección de bug"
git commit -m "docs: actualización de documentación"

# 4. Push
git push origin feature/nueva-funcionalidad

# 5. Crear Pull Request en GitHub

# 6. Code review

# 7. Merge a develop
```

### Conventional Commits

Tipos permitidos:
- `feat`: Nueva funcionalidad
- `fix`: Corrección de bug
- `docs`: Cambios en documentación
- `style`: Cambios de formato
- `refactor`: Refactorización sin cambio de comportamiento
- `perf`: Mejoras de rendimiento
- `test`: Cambios en tests
- `chore`: Cambios en build/deps

Ejemplo:
```
feat(backend): agregar endpoint GET /despachos/{id}
fix(frontend): corregir validación de formulario
docs(README): actualizar instrucciones de despliegue
```

---

## 📝 Estructura del Proyecto

```
despachos-devops/
├── back-Despachos_SpringBoot/          # Backend de Despachos
│   ├── Springboot-API-REST-DESPACHO/
│   │   ├── src/
│   │   ├── pom.xml
│   │   ├── Dockerfile
│   │   └── entrypoint.sh
│   └── ...
├── back-Ventas_SpringBoot/              # Backend de Ventas
│   ├── Springboot-API-REST/
│   │   ├── src/
│   │   ├── pom.xml
│   │   ├── Dockerfile
│   │   └── entrypoint.sh
│   └── ...
├── front_despacho/                      # Frontend React
│   ├── src/
│   ├── public/
│   ├── package.json
│   ├── Dockerfile
│   ├── vite.config.js
│   ├── tailwind.config.js
│   └── ...
├── infra/
│   ├── k8s/                            # Manifiestos Kubernetes
│   │   ├── backend-despacho.yml
│   │   ├── backend-ventas.yml
│   │   ├── frontend.yml
│   │   ├── mysql.yml
│   │   ├── configmap-secrets.yml
│   │   ├── hpa.yml
│   │   ├── ingress.yml
│   │   └── ...
│   └── terraform/                       # IaC Terraform (opcional)
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       └── ...
├── .github/
│   └── workflows/
│       ├── ci.yml                      # Pipeline GitHub Actions
│       └── ...
├── docker-compose.yml                  # Compose para desarrollo local
├── nginx.conf                          # Configuración Nginx
├── README.md                           # Este archivo
└── ...
```

---

## 🔐 Consideraciones de Seguridad

### ✅ Implementado

- [x] Imágenes Docker sin privilegios
- [x] Network Policies en Kubernetes (opcional)
- [x] Secrets para credenciales
- [x] RBAC básico
- [x] Health checks en todos los pods
- [x] Resource limits y requests
- [x] Logs centralizados

### ⚠️ Para Producción

- [ ] HTTPS/TLS en ALB
- [ ] WAF en ALB
- [ ] VPN para acceso administrativo
- [ ] MFA en AWS
- [ ] Backup automático de BD
- [ ] Disaster Recovery plan
- [ ] Monitoring avanzado (DataDog, New Relic)
- [ ] Auditoría completa

### Mejores prácticas

```bash
# Nunca commitear secretos
echo "*.env" >> .gitignore
echo "secrets/" >> .gitignore

# Usar AWS Secrets Manager para credenciales sensibles
aws secretsmanager create-secret --name db-password --secret-string 'mypassword'

# Usar IAM roles en lugar de access keys en pods
# Ver: https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html

# Scannear imágenes Docker para vulnerabilidades
docker scan backend-despacho:latest

# Actualizar dependencias regularmente
mvn versions:display-dependency-updates
npm audit fix
```

---

## 📚 Recursos y Referencias

### Documentación oficial

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Spring Boot](https://spring.io/projects/spring-boot)
- [React + Vite](https://vitejs.dev/)
- [Docker Documentation](https://docs.docker.com/)

### Tutoriales

- [AWS Workshop - EKS Immersion Day](https://www.eksworkshop.com/)
- [Kubernetes by Example](https://kubernetesbyexample.com/)
- [Deploy Spring Boot on Kubernetes](https://spring.io/guides/gs/spring-boot-docker/)

### Herramientas útiles

- [k9s](https://k9scli.io/) - Terminal UI para Kubernetes
- [kubectx](https://github.com/ahmetb/kubectx) - Cambiar contextos rápidamente
- [Lens](https://k8slens.dev/) - Kubernetes IDE
- [Docker Desktop](https://www.docker.com/products/docker-desktop) - Local development

---

## 📞 Soporte

### Obtener ayuda

1. **Revisar logs**:
   ```bash
   kubectl logs -f deployment/backend-despacho
   docker-compose logs -f
   ```

2. **Verificar recursos**:
   ```bash
   kubectl top nodes
   kubectl get events -w
   ```

3. **Revisar esta documentación**: Sección [Troubleshooting](#troubleshooting)

4. **Crear issue en GitHub**: [Create Issue](https://github.com/tu-usuario/despachos-devops/issues)

### Contacto del equipo

- **DevOps Lead**: [Tu nombre]
- **Backend Lead**: [Nombre]
- **Frontend Lead**: [Nombre]
- **Email**: devops@example.com

---

## 📄 Licencia

Este proyecto está bajo licencia **MIT**. Ver archivo [LICENSE](LICENSE) para más detalles.

---

## 🎯 Roadmap

### v1.0 (Actual)
- [x] Sistema básico funcionando
- [x] Despliegue en EKS
- [x] CI/CD automático
- [x] Autoscaling

### v1.1 (Próximo)
- [ ] Backend Ventas completamente integrado
- [ ] HTTPS/TLS
- [ ] Database backups automáticos
- [ ] Monitoring avanzado

### v2.0 (Futuro)
- [ ] Multi-region deployment
- [ ] Service Mesh (Istio)
- [ ] GraphQL API
- [ ] Mobile app

---

## 📊 Estadísticas del Proyecto

- **Servicios**: 3 (Frontend + 2 Backends)
- **Deployments**: 3
- **Replicas**: 5-13 (con autoscaling)
- **Base de Datos**: MySQL 8.0
- **Nodos**: 2-4 (con autoscaling)
- **Tiempo de despliegue**: ~10 minutos (AWS)
- **Uptime target**: 99.9%

---

**Última actualización**: 21 de Junio de 2024
**Versión de documentación**: 2.0
**Estado**: ✅ Producción Lista

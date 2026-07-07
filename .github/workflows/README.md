# GitHub Actions - CI/CD Pipeline

## Setup Inicial

### 1. Configurar Secretos en GitHub

Esta es la parte CRÍTICA. Ohne estos secretos, el pipeline no podrá:
- Conectarse a AWS
- Hacer push a ECR
- Desplegar a EKS

**Pasos:**

1. **Ir a GitHub:**
   - Repository → Settings
   - Secrets and variables → Actions
   - Click en "New repository secret"

2. **Agregar 3 secretos:**

   **Secreto 1: AWS_ACCESS_KEY_ID**
   ```
   Name: AWS_ACCESS_KEY_ID
   Value: AKIA... (tu access key)
   ```

   **Secreto 2: AWS_SECRET_ACCESS_KEY**
   ```
   Name: AWS_SECRET_ACCESS_KEY
   Value: xxxxxxxx... (tu secret key)
   ```

   **Secreto 3: AWS_ACCOUNT_ID**
   ```
   Name: AWS_ACCOUNT_ID
   Value: 123456789012
   ```

### 2. Verificar estructura de branches

El pipeline requiere:
- `main` - Producción
- `develop` - Desarrollo

```bash
git checkout -b develop
git push -u origin develop
```

### 3. Validar archivo del workflow

El archivo debe estar en:
```
.github/workflows/deploy.yml
```

## Como funciona el Pipeline

### Trigger (Disparo)

El workflow se ejecuta automáticamente cuando:
- Haces push a `main` (Deploy a producción)
- Haces push a `develop` (Deploy a desarrollo)
- Abres Pull Request a `main`

```bash
# Esto dispara el pipeline
git push origin main

# O esto
git push origin develop
```

### Jobs del Pipeline (en orden)

```
1. VALIDATE (30 segundos)
   └─ Valida Terraform, Docker, Kubernetes
   
2. BUILD paralelo (5-10 minutos)
   ├─ Build Backend Ventas + Test + Push a ECR
   ├─ Build Backend Despacho + Test + Push a ECR
   └─ Build Frontend + Build + Push a ECR
   
3. DEPLOY-DEV (solo si push a develop) (3 minutos)
   └─ Deploy a EKS en ambiente dev
   
4. DEPLOY-PROD (solo si push a main) (3 minutos)
   └─ Deploy a EKS en ambiente producción
```

**Tiempo total:** ~10-15 minutos

## Ver Progreso

### En GitHub UI

1. Repository → Actions tab
2. Seleccionar el último workflow
3. Ver estado de cada job:
   - Verde = Éxito
   - Rojo = Error
   - Amarillo = En progreso

### En Terminal

```bash
# Ver logs en tiempo real (requiere GitHub CLI)
gh run list --workflow deploy.yml
gh run view RUN_ID --log
```

## Troubleshooting

### Error: "Missing AWS credentials"

**Causa:** Secretos no configurados en GitHub

**Solución:**
```
1. GitHub → Settings → Secrets
2. Verificar que existan:
   - AWS_ACCESS_KEY_ID
   - AWS_SECRET_ACCESS_KEY
   - AWS_ACCOUNT_ID
```

### Error: "No such file or directory: Dockerfile"

**Causa:** Los Dockerfiles no están en la ruta esperada

**Solución:**
```bash
# Verificar estructura
ls back-Ventas_SpringBoot/Springboot-API-REST/Dockerfile
ls back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO/Dockerfile
ls front_despacho/Dockerfile
```

### Error: "Permission denied: cannot push to ECR"

**Causa:** AWS credentials no tienen permisos ECR

**Solución:**
```bash
# Verificar permiso en AWS IAM
# Usuario debe tener: AmazonEC2ContainerRegistryFullAccess
```

### Error: "kubectl: cluster not found"

**Causa:** El cluster EKS no existe o no está accesible

**Solución:**
```bash
# Verificar cluster
aws eks describe-cluster --name despachos-cluster --region us-east-1

# Verificar que terraform apply fue exitoso
terraform -chdir=infra/terraform output
```

## Monitorear Deployments

### Ver estado de la app

```bash
# Después de que el pipeline completa:
kubectl -n despacho-app get all

# Ver logs del deploy
kubectl -n despacho-app logs -f deployment/backend-ventas

# Ver eventos
kubectl -n despacho-app describe pod <pod-name>
```

### Ver imágenes en ECR

```bash
aws ecr describe-images --repository-name backend-ventas --region us-east-1

# Ver tags disponibles
aws ecr list-images --repository-name backend-ventas --region us-east-1
```

## Checklist antes de usar

- [ ] Secretos de AWS configurados en GitHub
- [ ] Rama `main` y `develop` existen
- [ ] EKS Cluster creado y accesible
- [ ] Terraform apply completado sin errores
- [ ] Dockerfile en cada ruta esperada
- [ ] package.json/pom.xml validos
- [ ] .env y variables.tfvars configurados

## Casos de uso comunes

### Desplegar a desarrollo

```bash
git checkout develop
# Hacer cambios...
git add .
git commit -m "feat: nueva feature"
git push origin develop

# Workflow se dispara automáticamente
# → Validar
# → Build
# → Deploy a dev
```

### Desplegar a producción

```bash
git checkout main
git merge develop  # (o desde GitHub UI)
git push origin main

# Workflow se dispara automáticamente
# → Validar
# → Build
# → Deploy a prod
```

### Pull Request (sin deploy)

```bash
git checkout -b feature/nueva-cosa
# Hacer cambios...
git push origin feature/nueva-cosa

# Abrir Pull Request en GitHub
# Workflow se ejecuta pero SIN deploy
# (Solo en PR a main, para validación)
```

## Seguridad

### Best Practices

1. **Nunca** commits credentials o secrets
2. **Usa** GitHub Secrets para valores sensibles
3. **Rota** AWS keys regularmente
4. **Revisa** logs pero **no** prints credentials
5. **Limita** permisos de usuarios en AWS

### Variables sensibles

Nunca poner en código:
```bash
# NUNCA HACER ESTO
aws_secret_access_key = "AKIA..."

# HACER ESTO
# En GitHub Secrets, luego usar en workflow:
aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

## Referencias

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [AWS ECR Push Action](https://github.com/aws-actions/amazon-ecr-login)
- [Kubernetes GitHub Deploy](https://github.com/azure/setup-kubectl)

---

**Última actualización:** 2026-07-05

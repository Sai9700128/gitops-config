# TaskFlow GitOps Repository

This repository contains Helm charts and ArgoCD applications for deploying the TaskFlow microservices application on Kubernetes.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         KUBERNETES CLUSTER                          │
│                                                                     │
│   [Internet Users]                                                  │
│          │                                                          │
│          ▼                                                          │
│   ┌─────────────────┐                                              │
│   │    frontend     │  ← LoadBalancer (public access)              │
│   │    port: 80     │                                              │
│   └────────┬────────┘                                              │
│            │                                                        │
│            ▼                                                        │
│   ┌─────────────────┐    ┌─────────────────┐                       │
│   │  user-service   │    │  task-service   │                       │
│   │ ExternalName    │    │ ExternalName    │  ← Internal only      │
│   │  port: 3001     │    │  port: 3002     │                       │
│   └────────┬────────┘    └────────┬────────┘                       │
│            │                      │                                 │
│            └──────────┬───────────┘                                 │
│                       ▼                                             │
│            ┌─────────────────────┐                                  │
│            │  mysql              │                                  │
│            │  ExternalName       │  ← Points to AWS RDS            │
│            └─────────────────────┘                                  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                        │
                        ▼
              ┌─────────────────────┐
              │      AWS RDS        │
              │  MySQL Database     │
              └─────────────────────┘
```

---

## Repository Structure

```
taskflow-gitops/
├── charts/
│   ├── frontend/           # React frontend application
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │
│   ├── user-service/       # User authentication microservice
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │
│   ├── task-service/       # Task management microservice
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│
└── README.md
```

---

## Services Overview

| Service | Type | Port | Description |
|---------|------|------|-------------|
| **frontend** | LoadBalancer | 80 | React application - public access |
| **user-service** | ClusterIP | 3001 | User authentication API - internal |
| **task-service** | ClusterIP | 3002 | Task management API - internal |

---

## Prerequisites

- Kubernetes cluster (EKS recommended)
- Helm 3.x installed
- ArgoCD installed in cluster
- AWS RDS MySQL instance
- Docker images pushed to registry (GHCR/ECR/DockerHub)

---

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/taskflow-gitops.git
cd taskflow-gitops
```

### 2. Update Configuration

Update `values.yaml` for each chart with your settings:

**charts/frontend/values.yaml:**

```yaml
image:
  repository: ghcr.io/YOUR_USERNAME/taskflow-frontend
  tag: "latest"

service:
  type: LoadBalancer
  port: 80
```

**charts/user-service/values.yaml:**

```yaml
image:
  repository: ghcr.io/YOUR_USERNAME/taskflow-user-service
  tag: "latest"

service:
  type: ClusterIP
  port: 3001

env:
  NODE_ENV: production
  PORT: "3001"
  DB_HOST: mysql
  DB_PORT: "3306"
  DB_NAME: users_db
  DB_USER: admin
  DB_PASSWORD: your-password
  JWT_SECRET: your-jwt-secret
  JWT_EXPIRES_IN: "24h"
```

**charts/task-service/values.yaml:**

```yaml
image:
  repository: ghcr.io/YOUR_USERNAME/taskflow-task-service
  tag: "latest"

service:
  type: ClusterIP
  port: 3002

env:
  NODE_ENV: production
  PORT: "3002"
  DB_HOST: mysql
  DB_PORT: "3306"
  DB_NAME: tasks_db
  DB_USER: admin
  DB_PASSWORD: your-password
  USER_SERVICE_URL: http://user-service:3001
  JWT_SECRET: your-jwt-secret
```

**charts/mysql/values.yaml:**

```yaml
service:
  externalName: your-rds-endpoint.region.rds.amazonaws.com
```

### 3. Deploy with ArgoCD

```bash
# Create ArgoCD applications
kubectl apply -f argocd/

# Verify applications
kubectl get applications -n argocd
```

### 4. Verify Deployment

```bash
# Check pods
kubectl get pods

# Check services
kubectl get svc

# Get frontend URL
kubectl get svc frontend
```

---

## Manual Helm Deployment (Without ArgoCD)

```bash
# Create namespace
kubectl create namespace taskflow

# Deploy MySQL ExternalName service first
helm install mysql ./charts/mysql -n taskflow

# Deploy backend services
helm install user-service ./charts/user-service -n taskflow
helm install task-service ./charts/task-service -n taskflow

# Deploy frontend
helm install frontend ./charts/frontend -n taskflow
```

---

## Useful Commands

### Check Deployment Status

```bash
# All pods
kubectl get pods

# All services
kubectl get svc

# Pod logs
kubectl logs -l app.kubernetes.io/name=user-service
kubectl logs -l app.kubernetes.io/name=task-service
kubectl logs -l app.kubernetes.io/name=frontend

# Describe pod (for debugging)
kubectl describe pod <pod-name>
```

### Helm Commands

```bash
# Test chart rendering
helm template frontend ./charts/frontend

# Install chart
helm install frontend ./charts/frontend

# Upgrade chart
helm upgrade frontend ./charts/frontend

# Uninstall chart
helm uninstall frontend

# List releases
helm list
```

### ArgoCD Commands

```bash
# List applications
kubectl get applications -n argocd

# Sync application
argocd app sync frontend

# Refresh application
argocd app refresh frontend

# Delete application
kubectl delete application frontend -n argocd
```

---

## Environment Variables

### user-service

| Variable | Description | Example |
|----------|-------------|---------|
| NODE_ENV | Environment | production |
| PORT | Service port | 3001 |
| DB_HOST | Database host | mysql |
| DB_PORT | Database port | 3306 |
| DB_NAME | Database name | users_db |
| DB_USER | Database user | admin |
| DB_PASSWORD | Database password | *** |
| JWT_SECRET | JWT signing key | *** |
| JWT_EXPIRES_IN | Token expiry | 24h |

### task-service

| Variable | Description | Example |
|----------|-------------|---------|
| NODE_ENV | Environment | production |
| PORT | Service port | 3002 |
| DB_HOST | Database host | mysql |
| DB_PORT | Database port | 3306 |
| DB_NAME | Database name | tasks_db |
| DB_USER | Database user | admin |
| DB_PASSWORD | Database password | *** |
| USER_SERVICE_URL | User service endpoint | <http://user-service:3001> |
| JWT_SECRET | JWT signing key | *** |

### frontend

| Variable | Description | Example |
|----------|-------------|---------|
| VITE_API_URL | Backend API URL | <http://user-service:3001> |

---

## Troubleshooting

### Pods in CrashLoopBackOff

```bash
# Check logs
kubectl logs <pod-name> --previous

# Common causes:
# - Database not accessible
# - Missing environment variables
# - Wrong image tag
```

### Service Not Accessible

```bash
# Check service exists
kubectl get svc

# Check endpoints
kubectl get endpoints <service-name>

# Test from inside cluster
kubectl run test --rm -it --image=busybox -- wget -qO- http://user-service:3001/health
```

### ArgoCD App Not Syncing

```bash
# Check app status
kubectl describe application <app-name> -n argocd

# Force refresh
argocd app refresh <app-name> --hard-refresh

# Check Helm template
helm template <chart-name> ./charts/<chart-name>
```

### Database Connection Issues

```bash
# Verify ExternalName service
kubectl get svc mysql -o yaml

# Test DNS resolution from pod
kubectl run test --rm -it --image=busybox -- nslookup mysql

# Check RDS security groups allow traffic from EKS
```

---

## Security Notes

⚠️ **Important:** For production:

1. **Never commit secrets** - Use HashiCorp Vault, AWS Secrets Manager, or Kubernetes Secrets
2. **Use HTTPS** - Configure Ingress with TLS
3. **Network Policies** - Restrict pod-to-pod communication
4. **RBAC** - Limit ArgoCD and service account permissions
5. **Image Scanning** - Scan images for vulnerabilities

---

## Future Enhancements

- [ ] HashiCorp Vault integration for secrets
- [ ] Ingress with TLS termination
- [ ] Horizontal Pod Autoscaler (HPA)
- [ ] Prometheus/Grafana monitoring
- [ ] Network Policies
- [ ] Pod Disruption Budgets

---

## Contributing

1. Create a feature branch
2. Make changes
3. Test with `helm template`
4. Submit PR

---

## License

MIT

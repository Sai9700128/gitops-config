# TaskFlow GitOps

Helm charts and ArgoCD manifests for TaskFlow application.

## Architecture
```
┌─────────────────────────────────────────────────────────┐
│                      TASKFLOW                           │
│                                                         │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐             │
│  │ Frontend │──▶│  Task    │──▶│  User    │             │
│  │  :80     │   │ Service  │   │ Service  │             │
│  │          │   │  :3002   │   │  :3001   │             │
│  └──────────┘   └────┬─────┘   └────┬─────┘             │
│                      │              │                   │
│                      └──────┬───────┘                   │
│                             │                           │
│                      ┌──────▼──────┐                    │
│                      │    MySQL    │                    │
│                      │    :3306    │                    │
│                      └─────────────┘                    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Structure
```
taskflow-gitops/
├── charts/
│   ├── user-service/
│   ├── task-service/
│   ├── frontend/
│   └── mysql/
├── apps/
│   └── taskflow.yaml
└── README.md
```

## Deploy with Helm (Manual)
```bash
# Create namespace
kubectl create namespace taskflow

# Deploy MySQL first
helm upgrade --install mysql ./charts/mysql -n taskflow

# Wait for MySQL
kubectl wait --for=condition=ready pod -l app=mysql -n taskflow --timeout=120s

# Deploy services
helm upgrade --install user-service ./charts/user-service -n taskflow
helm upgrade --install task-service ./charts/task-service -n taskflow
helm upgrade --install frontend ./charts/frontend -n taskflow
```

## Deploy with ArgoCD (GitOps)
```bash
kubectl apply -f apps/taskflow.yaml
```

## Useful Commands
```bash
# Check pods
kubectl get pods -n taskflow

# Check services
kubectl get svc -n taskflow

# View logs
kubectl logs -l app=user-service -n taskflow

# Port forward frontend
kubectl port-forward svc/frontend 8080:80 -n taskflow
```

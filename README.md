# TaskFlow GitOps Repository

This repository contains Helm charts, ArgoCD ApplicationSets, and deployment configurations for the TaskFlow cloud-native microservices platform running on Kubernetes (EKS).

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                            KUBERNETES CLUSTER (EKS)                          │
│                                                                              │
│   [Internet Users]                                                           │
│          │                                                                   │
│          ▼                                                                   │
│   ┌─────────────────┐                                                        │
│   │    frontend      │  ← LoadBalancer (public access)                       │
│   │    port: 80      │                                                       │
│   └────────┬─────────┘                                                       │
│            │                                                                  │
│            ▼                                                                  │
│   ┌─────────────────┐    ┌─────────────────┐                                 │
│   │  user-service    │    │  task-service    │  ← Core services               │
│   │  port: 3001      │    │  port: 3002      │                                │
│   └────────┬─────────┘    └────────┬─────────┘                                │
│            │                       │                                          │
│            └───────────┬───────────┘                                          │
│                        ▼                                                      │
│             ┌─────────────────────┐                                           │
│             │  mysql (RDS)        │  ← ExternalName → AWS RDS                 │
│             └─────────────────────┘                                           │
│                                                                               │
│   ┌───────────────────────────────────────────────────────────────────────┐   │
│   │              47 Microservices (via microservice-chart)                 │   │
│   │                                                                       │   │
│   │   Go (20)     Python (10)    Node.js (9)    Java (5)    Rust (3)     │   │
│   │   ports:      ports:         ports:          ports:      ports:       │   │
│   │   8081-8100   8101-8110      8111-8119       8120-8124   8125-8127   │   │
│   │                                                                       │   │
│   │   Deployed via ArgoCD ApplicationSet — auto-discovered from this repo │   │
│   └───────────────────────────────────────────────────────────────────────┘   │
│                                                                               │
│   ┌───────────────────────────────────────────────────────────────────────┐   │
│   │  Platform Services                                                    │   │
│   │  ArgoCD │ Prometheus │ Grafana │ Loki │ Istio │ Vault │ Gatekeeper   │   │
│   └───────────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Repository Structure

```
gitops-config/
├── helm/
│   ├── microservice-chart/          # Shared reusable Helm chart (all 47 services)
│   │   ├── Chart.yaml
│   │   ├── values.yaml              # Default values
│   │   └── templates/
│   │       ├── _helpers.tpl
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       ├── serviceaccount.yaml
│   │       └── hpa.yaml
│   │
│   ├── front-end/                   # Core — own full chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │
│   ├── user-service/                # Core — own full chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │
│   ├── task-service/                # Core — own full chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │
│   ├── base/                        # Network policy (default deny)
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       └── default-deny.yaml
│   │
│   ├── gatekeeper-constraints/      # OPA Gatekeeper constraints
│   │   ├── Chart.yaml
│   │   └── templates/
│   │
│   ├── gatekeeper-templates.yaml    # OPA Gatekeeper templates
│   │
│   ├── sso-service/                 # Go — per-service values only
│   │   └── values.yaml
│   ├── session-service/
│   │   └── values.yaml
│   ├── payment-service/             # Java — per-service values only
│   │   └── values.yaml
│   ├── email-service/               # Python — per-service values only
│   │   └── values.yaml
│   ├── notification-service/        # Node.js — per-service values only
│   │   └── values.yaml
│   ├── encryption-service/          # Rust — per-service values only
│   │   └── values.yaml
│   └── ... (47 service dirs total, each with only values.yaml)
│
├── applicationset.yaml              # ArgoCD ApplicationSet — auto-discovers all services
└── README.md
```

---

## Services Overview

### Core Services (Own Helm Charts)

| Service | Language | Type | Port | Description |
|---------|----------|------|------|-------------|
| **frontend** | TypeScript/React | LoadBalancer | 80 | React application — public access |
| **user-service** | Node.js | ClusterIP | 3001 | User authentication API — internal |
| **task-service** | Node.js | ClusterIP | 3002 | Task management API — internal |

### Microservices (Shared Chart — `microservice-chart`)

| Group | Services | Language | Ports | Purpose |
|-------|----------|----------|-------|---------|
| **Auth & Identity** | sso-service, session-service, rbac-service, token-service | Go | 8081-8083, 8098 | Authentication, sessions, roles, tokens |
| **API Infrastructure** | api-gateway-service, rate-limiter-service, request-validator, circuit-breaker-service, idempotency-service | Go | 8084-8085, 8095-8097 | Traffic routing, throttling, validation, resilience |
| **Platform Infrastructure** | config-service, cache-service, scheduler-service, service-registry, event-bus-service, queue-processor | Go | 8086-8088, 8092, 8094, 8100 | Configuration, caching, scheduling, messaging |
| **Observability** | health-aggregator, metric-collector, audit-log-service, feature-flag-service, webhook-service | Go | 8089-8091, 8093, 8099 | Health checks, metrics, audit trails, feature flags |
| **Data & Intelligence** | email-service, analytics-service, reporting-service, search-service, recommendation-service, ml-inference-service, data-pipeline-service, sentiment-service, export-service, geo-service | Python | 8101-8110 | Email, analytics, ML, search, data processing |
| **User Interaction** | notification-service, chat-service, file-upload-service, template-service, comment-service, activity-feed-service, realtime-service, markdown-service, localization-service | Node.js | 8111-8119 | Notifications, chat, files, real-time updates |
| **Billing & Finance** | payment-service, invoice-service, subscription-service, billing-service, compliance-service | Java | 8120-8124 | Payments, invoicing, subscriptions, compliance |
| **Performance-Critical** | encryption-service, image-processor, compression-service | Rust | 8125-8127 | Encryption, image processing, compression |

---

## How It Works

### Shared Helm Chart Pattern

The 47 microservices share a single Helm chart (`microservice-chart/`) instead of maintaining 47 separate charts. Each service only has a `values.yaml` that overrides what's unique:

```yaml
# helm/sso-service/values.yaml
image:
  repository: <ECR_REGISTRY>/taskflow-sso-service
  tag: "abc123"

service:
  port: 8081
```

Everything else (deployment spec, probes, resources, service account) comes from the shared chart's defaults.

### ArgoCD ApplicationSet

A single `applicationset.yaml` auto-discovers all service directories under `helm/` and creates ArgoCD Applications for each one. Adding a new service requires zero ArgoCD configuration — just add a `values.yaml` directory.

### CI/CD Pipeline

The app repo contains two GitHub Actions workflows:

**`ci-test.yaml`** (triggers on PR):

1. Detects which services changed via `git diff`
2. Spins up parallel matrix jobs for each changed service
3. Auto-detects language and runs appropriate tests
4. PR blocked until all tests pass

**`ci-build.yaml`** (triggers on merge to main):

1. Detects which services changed
2. Builds Docker images in parallel
3. Pushes to ECR
4. Updates image tags in this GitOps repo
5. ArgoCD detects the change and deploys

### Infrastructure (Terraform)

Terraform provisions per-service AWS resources using `for_each`:

- ECR repository per service
- CloudWatch log group per service
- Lifecycle policies for image cleanup

One module definition, one loop, 50 services provisioned.

---

## Prerequisites

- Kubernetes cluster (EKS)
- Helm 3.x
- ArgoCD installed in cluster
- AWS RDS MySQL instance
- ECR repositories (provisioned via Terraform)
- HashiCorp Vault (for secrets management)
- Istio service mesh
- Prometheus, Grafana, Loki (observability stack)

---

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/gitops-config.git
cd gitops-config
```

### 2. Deploy Core Services

```bash
# Deploy network policies
helm install base ./helm/base -n taskflow

# Deploy core services
helm install frontend ./helm/front-end -n taskflow
helm install user-service ./helm/user-service -n taskflow
helm install task-service ./helm/task-service -n taskflow
```

### 3. Deploy ApplicationSet

```bash
# This auto-discovers and deploys all 47 microservices
kubectl apply -f applicationset.yaml -n argocd
```

### 4. Verify

```bash
# Check all ArgoCD applications
kubectl get applications -n argocd

# Check all pods
kubectl get pods -n taskflow

# Check all services
kubectl get svc -n taskflow
```

---

## Adding a New Service

Adding a new service to the platform requires three steps across two repos:

**App repo:**

1. Create service directory with code + Dockerfile

**GitOps repo:**
2. Add `helm/<service-name>/values.yaml`

**Terraform:**
3. Add one line to `terraform.tfvars`: `"new-service" = { port = 8128 }`

No changes needed to CI workflows, Helm templates, or ArgoCD configuration. The ApplicationSet auto-discovers the new directory, CI auto-detects changes, and Terraform provisions the ECR repo.

---

## Useful Commands

### ArgoCD

```bash
# List all applications
kubectl get applications -n argocd

# Sync a specific service
argocd app sync sso-service

# Sync all applications
argocd app sync -l app.kubernetes.io/instance=taskflow-services

# Check app health
argocd app get sso-service
```

### Helm

```bash
# Test shared chart rendering for a specific service
helm template sso-service ./helm/microservice-chart -f ./helm/sso-service/values.yaml

# List all releases
helm list -n taskflow
```

### Debugging

```bash
# Check pod logs
kubectl logs -l app.kubernetes.io/name=sso-service -n taskflow

# Describe failing pod
kubectl describe pod <pod-name> -n taskflow

# Test service health from inside cluster
kubectl run test --rm -it --image=busybox -n taskflow -- wget -qO- http://sso-service:8081/health
```

---

## Security

- **HashiCorp Vault** — Centralized secrets management
- **OPA Gatekeeper** — Policy-as-code enforcement
- **Istio mTLS** — Service-to-service encryption
- **Network Policies** — Default deny with explicit allow rules
- **Trivy** — Container image scanning in CI
- **IAM Roles** — Least-privilege per service

---

## Observability

- **Prometheus** — Metrics collection and alerting rules
- **Grafana** — Dashboards for platform health
- **Loki** — Log aggregation
- **Tempo** — Distributed tracing
- **Kubecost** — Cost monitoring
- **CloudWatch** — Per-service log groups

---

## License

MIT

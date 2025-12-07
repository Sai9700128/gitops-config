📦 GitOps Configuration Repository

Single source of truth for Kubernetes cluster state. ArgoCD watches this repo and automatically syncs changes to the EKS cluster.

What's Inside:
- Kubernetes manifests (Deployments, Services, Ingress)
- ArgoCD Application definitions
- Environment-specific configurations (dev/prod)

GitOps Principles:
- Git is the source of truth
- All changes go through Git (no manual kubectl apply)
- Automated sync via ArgoCD
- Easy rollbacks with git revert

Related Repos:
- gitops-app - Application source code & CI pipeline

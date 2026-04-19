# rkamradt-helm-charts

Helm charts for the rkamradt platform, managed via ArgoCD app-of-apps pattern.

## Structure

```
apps/        # App of apps chart - creates ArgoCD Application resources
mongodb/     # MongoDB database
```

## Bootstrapping

The `apps` chart is the entry point. Deploy it once manually to ArgoCD and it
will manage everything else from that point forward.

### 1. Add this repo to ArgoCD

```bash
argocd repo add https://github.com/rkamradt/rkamradt-helm-charts \
  --username <github-user> \
  --password <github-pat>
```

### 2. Create the root app-of-apps Application

```bash
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: apps
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/rkamradt/rkamradt-helm-charts
    targetRevision: main
    path: apps
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```

ArgoCD will now sync all apps defined in `apps/values.yaml` automatically.

## Adding a new service

1. Create a new chart directory in this repo (e.g. `my-service/`)
2. Add an entry to `apps/values.yaml`:
   ```yaml
   - name: my-service
     path: my-service
     namespace: my-service
   ```
3. Push to main — ArgoCD will pick it up automatically.

## MongoDB

Other services can connect to MongoDB within the cluster at:

```
mongodb.mongodb.svc.cluster.local:27017
```

Connection string:
```
mongodb://admin:<password>@mongodb.mongodb.svc.cluster.local:27017/admin
```

The root password is stored in the `mongodb-secret` Secret in the `mongodb` namespace.

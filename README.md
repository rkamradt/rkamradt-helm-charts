# rkamradt-helm-charts

Helm charts for the rkamradt platform, managed via ArgoCD app-of-apps pattern.

## Structure

```
apps/                    # App of apps chart - creates ArgoCD Application resources
kafka/                   # Apache Kafka with ZooKeeper
mongodb/                 # MongoDB database
postgresql/              # PostgreSQL database
vehicleevent-api/        # Vehicle event API service
manufacturing-service/   # Manufacturing orchestration service
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

### 3. Setup GitHub Container Registry Authentication

Services need to pull images from GitHub Container Registry. See [GHCR-SETUP.md](GHCR-SETUP.md) for detailed instructions.

Quick setup:

```bash
./create-ghcr-secret.sh rkamradt-platform
```

You'll need a GitHub Personal Access Token with `read:packages` scope.

## Adding a new service

1. Create a new chart directory in this repo (e.g. `my-service/`)
2. Add an entry to `apps/values.yaml`:
   ```yaml
   - name: my-service
     path: my-service
     namespace: my-service
   ```
3. Push to main — ArgoCD will pick it up automatically.

## Infrastructure Services

### Kafka

Services can connect to Kafka at:
```
kafka.kafka.svc.cluster.local:9092
```

### MongoDB

Connection details:
```
Host: mongodb.mongodb.svc.cluster.local:27017
Connection String: mongodb://admin:<password>@mongodb.mongodb.svc.cluster.local:27017/admin
```
The root password is stored in the `mongodb-secret` Secret in the `mongodb` namespace.

### PostgreSQL

Connection details:
```
Host: postgresql.postgresql.svc.cluster.local:5432
Databases:
  - manufacturing (user: manufacturing_user, pass: manufacturing_pass)
  - vehicleevents (user: vehicle_user, pass: vehicle_pass)
```

Credentials are stored in the `postgresql-secret` Secret in the `postgresql` namespace.

# Container Image Status

## Current Situation

The Helm charts reference container images that don't yet exist in GitHub Container Registry (ghcr.io):

- `ghcr.io/rkamradt/vehicleevent-api:latest` - **Does not exist**
- `ghcr.io/rkamradt/manufacturing-service:latest` - **Does not exist**

## Service Analysis

### vehicleevent-api

This repository contains **API library code only** (Maven packages), not runnable services:
- Publishes Maven artifacts: `vehicleapi` and `lotapi` JARs to GitHub Packages
- No Dockerfile exists
- No container image is needed - this is a library consumed by other services

**Action Required**: Remove this from the Helm charts OR identify the actual runnable services that consume this API library.

### manufacturing-service

This repository has:
- ✅ A Dockerfile (`Dockerfile`)
- ✅ Runnable Spring Boot application
- ❌ No GitHub Actions workflow to build/push container images
- Uses local Docker builds only (docker-compose)

**Action Required**: Add GitHub Actions workflow to build and push container images to GHCR.

## Options to Fix

### Option 1: Remove vehicleevent-api Chart (Recommended)

Since vehicleevent-api is just a library, not a deployable service, we should remove its Helm chart.

```bash
cd rkamradt-helm-charts
rm -rf vehicleevent-api/
# Update apps/values.yaml to remove vehicleevent-api entry
```

### Option 2: Add GitHub Actions for manufacturing-service

Create `.github/workflows/docker-publish.yml` in the manufacturing-service repo:

```yaml
name: Build and Push Docker Image

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]
  pull_request:
    branches: [ main ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Log in to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha
            type=raw,value=latest,enable={{is_default_branch}}

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
```

### Option 3: Use Docker Hub Images

If images already exist on Docker Hub, update the Helm values:

```yaml
# manufacturing-service/values.yaml
image:
  repository: your-dockerhub-username/manufacturing-service
  tag: "latest"
  pullPolicy: IfNotPresent

# Remove imagePullSecrets or configure for Docker Hub
imagePullSecrets: []
```

### Option 4: Build Images Locally and Use Local Registry

For local development/testing:

```bash
# Build the image
cd ~/github/manufacturing-service
docker build -t localhost:5000/manufacturing-service:latest .

# Push to local registry (if running one)
docker push localhost:5000/manufacturing-service:latest

# Update Helm values
image:
  repository: localhost:5000/manufacturing-service
  tag: latest
```

## Recommended Next Steps

1. **Identify actual services**: Determine which services in the platform actually need to be deployed as containers
2. **Remove vehicleevent-api chart**: It's a library, not a deployable service
3. **Add CI/CD for manufacturing-service**: Create GitHub Actions workflow to build and publish images
4. **Update documentation**: Clarify which repositories contain deployable services vs. libraries

## Questions to Answer

1. Does vehicleevent-api have separate service repositories (update/query services) that should be deployed instead?
2. Should manufacturing-service images be published to ghcr.io or Docker Hub?
3. Are there other services in the platform that need Helm charts?

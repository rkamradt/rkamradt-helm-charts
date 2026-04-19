# GitHub Container Registry Authentication Setup

The `vehicleevent-api` and `manufacturing-service` deployments pull container images from GitHub Container Registry (ghcr.io). This requires authentication.

## Prerequisites

1. **GitHub Personal Access Token (PAT)** with `read:packages` scope
   - Go to: https://github.com/settings/tokens
   - Click "Generate new token" → "Generate new token (classic)"
   - Select scope: `read:packages`
   - Generate and save the token securely

2. **kubectl** configured and connected to your cluster

## Quick Setup

Use the provided script to create the secret:

```bash
./create-ghcr-secret.sh rkamradt-platform
```

You'll be prompted for:
- Your GitHub username
- Your GitHub Personal Access Token

## Manual Setup

If you prefer to create the secret manually:

```bash
# Replace with your actual credentials
GITHUB_USERNAME="your-github-username"
GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
NAMESPACE="rkamradt-platform"

kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=$GITHUB_USERNAME \
  --docker-password=$GITHUB_TOKEN \
  --docker-email="${GITHUB_USERNAME}@users.noreply.github.com" \
  --namespace=$NAMESPACE
```

## Verification

Check that the secret was created:

```bash
kubectl get secret ghcr-secret -n rkamradt-platform
```

Check pod status after secret creation:

```bash
kubectl get pods -n rkamradt-platform
```

If pods are still in ImagePullBackOff, delete them to force a restart:

```bash
kubectl delete pod -l app=vehicleevent-api -n rkamradt-platform
kubectl delete pod -l app=manufacturing-service -n rkamradt-platform
```

## Using YAML (Alternative)

You can also create a YAML file with the secret:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ghcr-secret
  namespace: rkamradt-platform
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <base64-encoded-docker-config>
```

To generate the base64-encoded value:

```bash
echo -n '{"auths":{"ghcr.io":{"username":"YOUR_USERNAME","password":"YOUR_TOKEN","email":"YOUR_USERNAME@users.noreply.github.com","auth":"'$(echo -n YOUR_USERNAME:YOUR_TOKEN | base64)'"}}}' | base64 -w 0
```

## Security Notes

1. **Never commit tokens to Git** - The secret should only exist in your Kubernetes cluster
2. **Use minimal permissions** - The PAT only needs `read:packages` scope
3. **Rotate tokens regularly** - Update the secret when you rotate your PAT
4. **Per-namespace secrets** - Each namespace needs its own secret

## Troubleshooting

### Images are still failing to pull

1. Verify the secret exists:
   ```bash
   kubectl get secret ghcr-secret -n rkamradt-platform
   ```

2. Check if the secret is correctly formatted:
   ```bash
   kubectl get secret ghcr-secret -n rkamradt-platform -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d
   ```

3. Verify the token has correct permissions on GitHub:
   - Go to: https://github.com/settings/tokens
   - Check that the token has `read:packages` scope

4. Check that the images exist and are accessible:
   ```bash
   docker login ghcr.io -u YOUR_USERNAME -p YOUR_TOKEN
   docker pull ghcr.io/rkamradt/vehicleevent-api:latest
   docker pull ghcr.io/rkamradt/manufacturing-service:latest
   ```

### Secret exists but pods still get 403

The Helm charts reference `imagePullSecrets[0].name: ghcr-secret`. If you named your secret differently, either:

1. Recreate the secret with the correct name (`ghcr-secret`), or
2. Update the Helm chart values to use your secret name

## For Multiple Namespaces

If you deploy services to different namespaces, create the secret in each:

```bash
./create-ghcr-secret.sh rkamradt-platform
./create-ghcr-secret.sh another-namespace
```

Or use kubectl to copy the secret:

```bash
kubectl get secret ghcr-secret -n rkamradt-platform -o yaml | \
  sed 's/namespace: rkamradt-platform/namespace: another-namespace/' | \
  kubectl apply -f -
```

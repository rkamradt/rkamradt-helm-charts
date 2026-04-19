#!/bin/bash
# Script to create GitHub Container Registry pull secret for Kubernetes

set -e

echo "GitHub Container Registry Secret Creator"
echo "========================================="
echo ""

# Check if namespace is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <namespace> [github-username] [github-token]"
    echo ""
    echo "Examples:"
    echo "  $0 rkamradt-platform"
    echo "  $0 rkamradt-platform myuser ghp_xxxxxxxxxxxxx"
    echo ""
    echo "If username and token are not provided, you'll be prompted for them."
    exit 1
fi

NAMESPACE=$1
GITHUB_USERNAME=${2:-}
GITHUB_TOKEN=${3:-}

# Prompt for credentials if not provided
if [ -z "$GITHUB_USERNAME" ]; then
    read -p "Enter your GitHub username: " GITHUB_USERNAME
fi

if [ -z "$GITHUB_TOKEN" ]; then
    read -sp "Enter your GitHub Personal Access Token (with read:packages scope): " GITHUB_TOKEN
    echo ""
fi

# Validate inputs
if [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GitHub username and token are required"
    exit 1
fi

echo ""
echo "Creating secret 'ghcr-secret' in namespace '$NAMESPACE'..."

# Create namespace if it doesn't exist
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Create the docker-registry secret
kubectl create secret docker-registry ghcr-secret \
    --docker-server=ghcr.io \
    --docker-username="$GITHUB_USERNAME" \
    --docker-password="$GITHUB_TOKEN" \
    --docker-email="${GITHUB_USERNAME}@users.noreply.github.com" \
    --namespace="$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "✓ Secret 'ghcr-secret' created successfully in namespace '$NAMESPACE'"
echo ""
echo "To verify the secret:"
echo "  kubectl get secret ghcr-secret -n $NAMESPACE"
echo ""
echo "Note: You need to run this script for each namespace that needs to pull images:"
echo "  ./create-ghcr-secret.sh rkamradt-platform"

#!/bin/bash

set -e

# start minikube with docker driver
# resources are set to minimum
echo "Starting minikube..."
minikube start --driver=docker --memory=2048 --cpus=2

echo

# adding helm repos
echo "Adding helm repos..."

helm repo add argo https://argoproj.github.io/argo-helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
echo

# installing argocd
echo "Installing ArgoCD..."
helm install argocd argo/argo-cd -n argocd --create-namespace -f argocd-values.yaml

# installing prometheus and grafana
echo
echo "Installing Prometheus..."

helm install prometheus prometheus-community/prometheus -n monitoring --create-namespace -f prometheus-values.yaml
echo
echo "Installing Grafana..."

helm install grafana grafana/grafana -n monitoring -f grafana-values.yaml
echo
echo "Setup complete"
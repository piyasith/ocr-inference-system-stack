# OCR Microservices Deployment with Minikube, ArgoCD, Prometheus, and Grafana

---

## 🏋️ Project Overview

This project sets up a complete **OCR microservices architecture** on **Minikube**, using:
- **Docker** for building/pushing images
- **Helm** for Kubernetes deployments
- **ArgoCD** for GitOps deployments
- **Prometheus** for metrics scraping
- **Grafana** for model monitoring dashboards

---

## 🏢 Architecture Diagram

```
User → API Gateway (FastAPI)
  → Model Server (KServe Model)
    → Exposes /metrics
      → Prometheus scrapes /metrics
        → Grafana reads Prometheus metrics
ArgoCD → Deploys API Gateway and Model Server via Helm Charts
All components inside Minikube cluster
```

---

## 🔍 Components

| Component       | Purpose                           |
|-----------------|-----------------------------------|
| API Gateway     | FastAPI service handling requests |
| Model Server    | KServe-based OCR model             |
| Prometheus      | Scrapes model metrics              |
| Grafana         | Visualizes monitoring dashboards   |
| ArgoCD          | Automates deployments (GitOps)     |
| Minikube        | Local Kubernetes cluster           |

---

## 🏠 Local Testing

### 1. App Test

```bash
# Install Poetry
curl -sSL https://install.python-poetry.org | python3 -

# Install dependencies
poetry install

# Run services locally
poetry run python model.py &
poetry run python api-gateway.py &

# Test OCR Endpoint
curl -X POST -F "image_file=@images.jepg" http://localhost:8001/gateway/ocr
```

---

### 2. Build and Push Docker Images

```bash
# Run the bash script to build and test the images
bash docker_build_test.sh

docker tag model-server piyasith/ocr-model-server:latest
docker push piyasith/ocr-model-server:latest

docker tag api-gateway piyasith/ocr-api-gateway:latest
docker push piyasith/ocr-api-gateway:latest
```

#### a. Base Image Selection Rationale:

Chose python:3.11-slim because:
    It's small (~29MB) and secure.
    Good balance between size and compatibility.
    Easier to patch and maintain.

Using official Python images ensures long-term support and regular security patches.

#### b. Security Considerations:

Minimize image size: slim variant reduces attack surface.

Remove apt caches after installing (rm -rf /var/lib/apt/lists/*) to prevent layer bloating.

Non-root user (optional upgrade): you could run as a non-root user inside the container for extra security.

Private repo: Docker Hub allows 1 free private repo — keeping your containers private is good practice.

#### c. Build Optimization Techniques:

Multi-stage builds.

Layer caching: Copy pyproject.toml + poetry.lock first, install deps, then copy code — so deps don’t reinstall every rebuild unless they change.

No virtualenv inside container (poetry config virtualenvs.create false) — save disk/memory.

---

## 🔧 Setup Instructions

### Prerequisites

- Docker
- Minikube
- kubectl
- Helm
- Access to DockerHub

---

### 1. Start Minikube

```bash
minikube start --driver=docker --memory=2048 --cpus=2
```

---

### 2. Install Core Services Using Helm

```bash
# ArgoCD
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd -n argocd --create-namespace

# Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/prometheus -n monitoring --create-namespace

# Grafana
helm repo add grafana https://grafana.github.io/helm-charts
helm install grafana grafana/grafana -n monitoring
```

---

### 3. Deploy Applications via ArgoCD

```bash
kubectl apply -f argo-cd/app-project.yaml
kubectl apply -f argo-cd/applicationset-model-server.yaml
kubectl apply -f argo-cd/applicationset-api-gateway.yaml
```

ArgoCD automatically syncs and deploys both services!

---

## 📊 Monitoring with Prometheus + Grafana

### Exposing Metrics
- Model server exposes Prometheus metrics at `/metrics` on port `8080`.
- Prometheus scrapes based on Kubernetes annotations.

### Grafana Dashboard Panels

| Metric                        | Query Example |
|-------------------------------|---------------|
| Total Inference Requests      | `sum(rate(kserve_inference_request_count[1m]))` |
| Inference Error Rate          | `sum(rate(kserve_inference_request_error_count[1m]))` |
| Inference Latency (p95)        | `histogram_quantile(0.95, sum(rate(kserve_inference_request_duration_seconds_bucket[5m])) by (le))` |
| CPU Usage                     | `rate(container_cpu_usage_seconds_total{pod=~"model-server.*"}[1m])` |
| Memory Usage                  | `container_memory_usage_bytes{pod=~"model-server.*"}` |

# DevSecOps Pipeline Project - Static Web App on Kubernetes

## Important Note - Experimental / Learning Project

**This project is built purely for experimental and learning purposes (Proof of Concept / Hands-on Practice).**

- The application itself is a very simple static web app (Nginx serving static files).
- All the tools used in this project (Jenkins, Trivy, Helm, ArgoCD, Prometheus, Grafana, etc.) have been added **for experimentation and learning**, and not because the project actually required all of them in a real-world scenario.
- The main goal of this project is to gain practical hands-on experience in building a complete **DevSecOps Pipeline** on Kubernetes using various tools and technologies.
- Some tools were included only for exploration and to experiment with different DevSecOps practices.

In short: This is a **learning/experimental project**, not intended for production use or a complex real-world application.

---

This project demonstrates a complete **DevSecOps workflow** for a simple static web application served by **Nginx**.
It covers the full delivery lifecycle from source code to secure deployment using:

- **Jenkins** for CI/CD orchestration
- **Docker** for containerization
- **Kubernetes (Minikube)** for local cluster deployment
- **Helm** for reusable Kubernetes packaging
- **ArgoCD** for optional GitOps-based continuous delivery
- **Trivy** for container and filesystem vulnerability scanning
- **Prometheus & Grafana** (optional) for monitoring and observability

---
## Architecture Overview
[Project Structure Diagram]  
<img width="1536" height="1024" alt="Project Architecture" src="https://github.com/user-attachments/assets/b7787b3c-c0c1-4126-a8d8-89e05821f633" />

**End-to-end flow:**  
**Developer → GitHub → Jenkins → Trivy Scan → Helm Deploy → Kubernetes → (Optional ArgoCD & Monitoring)**

### Pipeline Flow Details
1. Developer pushes code to GitHub.
2. Jenkins pipeline is triggered (`githubPush` trigger).
3. Jenkins checks out source code.
4. Jenkins uses the prebuilt Docker Hub image `minac4/iti-pro:latest`.
5. Trivy scans the image and repository for vulnerabilities.
6. Helm deploys/updates the release on Kubernetes.
7. Kubernetes runs the app and exposes it via Service/Ingress.
8. Optional:
   - ArgoCD continuously syncs manifests/charts from Git.
   - Prometheus scrapes metrics using `ServiceMonitor`, and Grafana visualizes dashboards.

---
## Project Structure
### Key Files
- `Dockerfile`: Builds the Nginx unprivileged image serving static files on port `8080`.
- `Jenkinsfile`: Defines CI/CD stages (checkout, build, Trivy scan, test, Helm deploy, verify).
- `k8s/`: Raw Kubernetes manifests (Deployment and Service).
- `helm/iti-pro/`: Helm chart used by Jenkins and ArgoCD deployments.
- `argocd-iti-pro.yaml`: ArgoCD `Application` manifest for GitOps sync.
- `iti-pro-servicemonitor.yaml`: Optional Prometheus Operator monitor configuration.

---
## Prerequisites
Install and configure the following tools:
- Docker
- Minikube
- kubectl
- Helm
- Jenkins (with required plugins and cluster access)
- Trivy
- Optional: ArgoCD CLI + ArgoCD server
- Optional: Prometheus + Grafana (or `kube-prometheus-stack`)

---
## Setup & Installation

### 1) Start Minikube
```bash
minikube start
2) Enable Ingress Addon
Bashminikube addons enable ingress
3) Use the Prebuilt Docker Hub Image
Bashdocker pull minac4/iti-pro:latest
4) Deploy with Helm
Bashhelm upgrade --install minac4-iti-pro helm/iti-pro \
  --namespace default \
  --set image.repository=minac4/iti-pro \
  --set image.tag=latest \
  --set image.pullPolicy=IfNotPresent \
  --wait \
  --timeout 3m
5) Verify Deployment
Bashkubectl get pods -l app.kubernetes.io/name=minac4-iti-pro
kubectl get svc minac4-iti-pro
kubectl rollout status deployment/minac4-iti-pro --timeout=90s
6) Access the Application
Option A - NodePort:
Bashminikube service minac4-iti-pro --url
Option B - Ingress:
Bashkubectl get ingress

CI/CD Pipeline (Jenkins)
The Jenkinsfile implements the following stages:

Checkout Code
Pulls source code from SCM.

Use Docker Hub Image
Uses the prebuilt image minac4/iti-pro:latest.

Security Scan (Trivy)
Fails pipeline on CRITICAL image vulnerabilities.
Reports HIGH findings without failing the build.
Scans filesystem for HIGH,CRITICAL.

Tests
Placeholder stage for unit/integration tests.

Deploy (Helm)
Runs helm upgrade --install with image overrides.

Verify
Checks pods, service, and deployment rollout status.



Security (Trivy)
Trivy is used as a quality gate in CI:

Image scan (blocking):
trivy image --exit-code 1 --severity CRITICAL minac4/iti-pro:latest
Image scan (non-blocking report):
trivy image --exit-code 0 --severity HIGH minac4/iti-pro:latest
Filesystem scan (non-blocking report):
trivy fs --exit-code 0 --severity HIGH,CRITICAL .

Severity Handling Strategy

CRITICAL vulnerabilities: Pipeline fails and deployment is blocked.
HIGH vulnerabilities: Logged for review/remediation, pipeline continues.


ArgoCD (Optional)
This repository includes argocd-iti-pro.yaml to deploy the Helm chart via GitOps.
Deploy ArgoCD Application
Bashkubectl apply -f argocd-iti-pro.yaml
Check and Sync
Using ArgoCD CLI:
Bashargocd app get minac4-iti-pro
argocd app sync minac4-iti-pro
Using kubectl:
Bashkubectl -n argocd get applications

Monitoring (Optional)
You can integrate Prometheus & Grafana for observability.

Apply the provided ServiceMonitor:

Bashkubectl apply -f iti-pro-servicemonitor.yaml

Ensure Prometheus Operator selects the release: monitoring label.
Confirm target discovery in Prometheus UI.
Build Grafana dashboards for request rate, availability, and latency (if metrics are available).

ServiceMonitor Purpose
iti-pro-servicemonitor.yaml tells Prometheus how to scrape the service endpoint (port: http, path: /, interval: 30s) from the default namespace.

Screenshots
Jenkins Pipeline
<img src="docs/images/jenkins-pipeline.png" alt="Jenkins Pipeline">
ArgoCD Application
<img src="docs/images/argocd.png" alt="ArgoCD Application">
Prometheus Query View
<img src="docs/images/prometheus.png" alt="Prometheus Query">
Kubernetes Dashboard
<img src="docs/images/kubernetes-dashboard.png" alt="Kubernetes Dashboard">

Troubleshooting
1) ImagePullBackOff
Cause: Cluster cannot pull minac4/iti-pro:latest.
Fix:
Bashdocker pull minac4/iti-pro:latest
kubectl set image deployment/minac4-iti-pro minac4-iti-pro=minac4/iti-pro:latest --record
Make sure image.pullPolicy=IfNotPresent is set in Helm values.
2) CrashLoopBackOff
Cause: Application process fails, wrong port, or failing probes.
Fix:
Bashkubectl logs deployment/minac4-iti-pro
kubectl describe pod <pod-name>
Verify the container listens on port 8080 and probes are correctly configured.
3) Resource Quota / Scheduling Errors
Fix:
Bashminikube stop
minikube start --cpus=4 --memory=4096
You can also reduce resource requests/limits in helm/iti-pro/values.yaml.

Clean Up
Bashhelm uninstall minac4-iti-pro -n default
kubectl delete -f ingress.yaml --ignore-not-found
kubectl delete -f iti-pro-servicemonitor.yaml --ignore-not-found
kubectl delete -f argocd-iti-pro.yaml --ignore-not-found
To delete the Minikube cluster:
Bashminikube delete

# Student Management System - Kubernetes & Jenkins CI/CD

Student App – Kubernetes + Jenkins CI/CD Pipeline

A fully automated CI/CD pipeline for deploying a containerized Student Management Application to a Kubernetes cluster using Jenkins, Docker, and Helm.This project demonstrates a real‑world DevOps workflow from code commit to production deployment.

📌 Overview

This repository contains:

A simple Student Management Application

A Dockerfile to containerize the app

Kubernetes manifests for deployment

A Helm chart for templated deployments

A complete Jenkins CI/CD pipeline (Jenkinsfile)

The goal is to provide a clean, reproducible DevOps pipeline suitable for learning, demos, and real‑world use.

🏗️ Architecture

Developer → GitHub → Jenkins Pipeline → Docker Registry → Kubernetes Cluster → End Users

Components

Application — simple student app packaged as a container

Docker — builds and packages the app

Jenkins — automates CI/CD pipeline

Kubernetes — runs the application

Helm — manages Kubernetes deployments

🔁 CI/CD Pipeline Flow

1. Developer pushes code to GitHub
2. Jenkins webhook triggers pipeline
3. Jenkins builds Docker image
4. Jenkins runs tests (optional)
5. Jenkins pushes image to registry
6. Jenkins deploys to Kubernetes using Helm or kubectl
7. Kubernetes rolls out updated application

📁 Repository Structure

student-app-k8s-jenkins-cicd/
│
├── app/                     # Application source code
│   ├── Dockerfile
│   └── src/
│
├── k8s/                     # Raw Kubernetes manifests
│   ├── deployment.yaml
│   ├── service.yaml
│   └── namespace.yaml
│
├── helm/                    # Helm chart for deployment
│   ├── templates/
│   ├── values.yaml
│   └── Chart.yaml
│
├── Jenkinsfile              # CI/CD pipeline definition
└── README.md

🐳 Docker

Build Image

docker build -t student-app:latest ./app

Run Locally

docker run -p 8080:8080 student-app

☸️ Kubernetes Deployment

Apply Manifests

kubectl apply -f k8s/

Deploy with Helm

helm install student-app ./helm

Upgrade Release

helm upgrade student-app ./helm

🧪 Jenkins Pipeline

The Jenkinsfile includes:

Source checkout

Docker image build

Optional test stage

Push to container registry

Deployment to Kubernetes

Post‑build cleanup

You must configure Jenkins with:

Docker credentials

Kubernetes cluster access (kubeconfig)

GitHub webhook

🌐 Accessing the Application

NodePort

kubectl get svc student-app-service

LoadBalancer (Cloud)

kubectl get svc

🚀 Future Enhancements

Add Prometheus + Grafana monitoring

Add Ingress + TLS

Add automated test suite

Add GitOps (ArgoCD / FluxCD)

Add Canary or Blue‑Green deployments

🤝 Contributing

Contributions are welcome.Open an issue or submit a pull request to propose improvements.

📄 License

This project is licensed under the MIT License.

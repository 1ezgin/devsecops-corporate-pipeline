🚀 DevSecOps Pipeline: Spring PetClinic + Kubernetes

🎯 Project Overview

This repository contains a demonstration of a comprehensive CI/CD pipeline for a Spring PetClinic Java application, fully integrated with essential DevSecOps tooling.

Goal: To establish an automated pipeline covering building, testing, quality analysis (SonarQube), security scanning (Trivy), artifact management (Nexus), and deployment to a Kubernetes cluster.

🛠️ Technology Stack

Category

Tool

Purpose

Application

Java 17, Spring Boot

Application source code.

CI/CD Orchestration

Jenkins (Declarative Pipeline)

Pipeline automation and management.

Build Tool

Maven 3

Compilation, unit testing, and packaging.

Artifact Management

Nexus Repository Manager (3.x)

Storage for built JAR artifacts.

Code Analysis

SonarQube

Static code quality and security analysis.

Security (SAST/DAST)

Trivy

Vulnerability scanning for filesystems and Docker images.

Containerization

Docker

Packaging the application into an isolated image.

Orchestration

Kubernetes (k3s/k8s)

Application deployment and scaling.

⚙️ CI/CD Pipeline Flow (Jenkinsfile)

The Declarative Pipeline is structured around the following key stages:

Git Checkout: Fetches the source code from GitHub.

Build and Test: Compiles the application using Maven, runs Unit Tests (-DskipITs is used to skip Docker-dependent integration tests).

File System Scan (Trivy): Scans the source code and dependencies for vulnerabilities.

SonarQube Analysis & Quality Gate: Executes deep code analysis and waits for the quality gate to pass.

Publish to Nexus: Uploads the final JAR artifact to the Nexus Snapshot Repository.

Build and Tag Docker Image: Creates the Docker image (1ezgin/corp:latest).

Docker Image Scan (Trivy): Scans the built Docker image for OS and library vulnerabilities.

Push Docker Image: Publishes the final image to Docker Hub.

Deploy to k8s: Automatic deployment to the webapps Namespace (conditional, runs only on the main branch).

🔑 Configuration and Setup

The following Credential IDs must be configured within Jenkins Credentials Management for the pipeline to run successfully:

Credentials ID

Type

Purpose

sonar-token

Secret Text

Authentication token for SonarQube access.

docker-cred

Username with password

Docker Hub credentials for image push/pull.

k8-cred

Secret File/Kubeconfig

ServiceAccount token for Kubernetes cluster access.

global-settings

Managed File (Settings.xml)

Maven configuration for Nexus access credentials.

1. Nexus Configuration

The <distributionManagement> block in pom.xml is configured to deploy artifacts to the Nexus Snapshot repository:

[http://18.198.2.150:8081/repository/maven-snapshots/](http://18.198.2.150:8081/repository/maven-snapshots/)


2. Kubernetes Deployment

The application is deployed using the deployment-service.yaml manifest:

Namespace: webapps

Service Type: NodePort

External Access Port: 30080

Upon successful deployment, the application is accessible via: http://<YOUR_WORKER_NODE_IP>:30080

3. Email Notifications Setup

The post section in the Jenkinsfile is configured to send status notifications (Success/Failure) via Google SMTP, using an App Password for the recipient address: ${RECIPIENT_EMAIL}.

⚠️ Troubleshooting & Known Issues

Issue

Root Cause

Status/Mitigation

Kubernetes Deployment Failure

Deployment to K8s failed due to invalid k8-cred (ServiceAccount token) or improper Kubelet configuration, preventing kubectl apply execution from Jenkins.

Fixed: Required manual deployment. The final step depends on correct k8-cred setup.

Worker Node connection failure

Kubernetes Worker Node was stuck in NotReady status (likely CNI misconfiguration or firewall issue on the VM).

Monitoring skipped: The monitoring stack (Prometheus/Grafana) was skipped due to the inability to connect the Worker Node. The application runs, but the infrastructure metrics collection is currently blocked.

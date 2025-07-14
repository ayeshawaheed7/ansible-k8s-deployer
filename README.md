# Automated Java + MySQL Deployment on AWS: EC2 to Kubernetes with Ansible & Helm

## Overview

This project automates the deployment of a Java web application backed by a MySQL database. It begins with a traditional virtual machine-based infrastructure on AWS and transitions into a modern, containerized Kubernetes setup. Provisioning, configuration, and deployments are fully automated using Ansible and Helm.

## Problem Statement

A robust and automated setup was required to deploy and manage a Java web application and its MySQL database on AWS. Initially, a traditional virtual machine–based setup without containers was used. Over time, the need emerged to:

* Automate the setup of infrastructure and applications from scratch.
* Secure the database by restricting external access.
* Enable the reliable deployment of a Java web app and MySQL DB on AWS.
* Transition to Kubernetes for better maintainability and scalability.
* Improve database availability using a replicated setup.

## Solution Summary

The project is implemented in three key phases:

---

### Phase 1: Traditional Setup on AWS with Ansible

**Infrastructure:**

* A dedicated **Ansible control server** is provisioned in a public subnet.
* Two EC2 instances are created within the same VPC:

  * A **web server** to host the Java application (with a public IP).
  * A **database server** for MySQL (without a public IP, isolated in a private subnet).

**Execution Flow:**

The provisioning and configuration are broken into logical playbooks to follow best practices:

1. **`ec2-provisioning-iam-role.yml`**

   * Instead of passing AWS credentials directly, this playbook creates an IAM role with least privilege access.
   * This enables passwordless, scoped access to provision resources securely and aligns with AWS security best practices.

2. **`provision-ansible-server.yml`**

   * Provision the dedicated Ansible server in a public subnet.

3. **`configure-ansible-server.yml`**

   * Installs required tools (e.g., Ansible, Git) on the Ansible server.
   * Copies all necessary playbooks and configurations to the server for downstream provisioning.

At this point, SSH into the **Ansible server**, and from there:

4. **`provision-app-servers.yml`**

   * Provision the two application servers: one for MySQL (private subnet) and one for the Java web app (public subnet).

5. **`configure-app-servers.yml`**

   * Installs MySQL on the DB server using the `geerlingguy.mysql` role.
   * Deploys and starts the Java application on the web server.

**Security:**

* The **database server** is in a **private subnet** and doesn't have direct internet access.
* A **NAT Gateway** enables the DB server to download dependencies securely without being exposed publicly.

**Outcome:**

The Java application becomes accessible via:
`http://<web-server-public-ip>:8080`

---

### Phase 2: Dockerized Deployment on Kubernetes

To modernize deployment and reduce manual operations, the application was migrated from traditional EC2-based infrastructure to a Kubernetes-based architecture. The goal was to simplify rollout, improve scalability, and streamline configuration through declarative and automated workflows.

**Key Configurations:**

* The Java application was **containerized** and pushed to a **Docker registry**.
* Kubernetes manifests were created for:

  * **Deployments** and **Services** for both the Java application and the MySQL database (single replica).
  * **ConfigMaps** to inject non-sensitive configuration variables into pods.
  * **Secrets** to securely provide sensitive data like database credentials and Docker registry authentication.
* An **NGINX Ingress Controller** was deployed via Helm to manage external HTTP traffic.
* An **Ingress resource** exposed the Java application through a browser-friendly URL.

**Execution Flow:**

The entire Kubernetes setup is automated using a dedicated Ansible playbook:

1. **`deploy-k8s-app-db-single-replica.yaml`**

   This playbook performs the following steps:

   * **Create the MySQL ConfigMap**
     Injects non-sensitive environment variables (like database name, host, etc.) into the MySQL pod using a manifest file (`db-configmap.yaml`).

   * **Render and Apply Kubernetes Secrets from Template**
     Templated secret files (`db-secret.yaml.j2`) are rendered using sensitive variables loaded from `group-vars/vault.yaml`, ensuring no plaintext secrets are exposed. This includes database usernames and passwords.

   * **Deploy Docker Registry Secret**
     A Kubernetes Secret of type `kubernetes.io/dockerconfigjson` is created to allow Kubernetes to pull private container images from Docker Hub using encoded credentials.

   * **Deploy Applications**
     The MySQL deployment (`mysql.yaml`) and the Java application (`java-app.yaml`) are applied to the cluster.

   * **Deploy NGINX Ingress Controller via Helm**
     Helm is used to deploy the ingress controller in the `ingress` namespace with service publishing enabled.

   * **Deploy Java Application Ingress**
     Finally, the ingress resource (`java-app-ingress.yaml`) is applied to route external traffic to the Java application service.

**Outcome:**

The application is successfully deployed in Kubernetes and becomes accessible at:
`http://<nginx-ingress-loadbalancer-address>`

---

### Phase 3: High Availability MySQL Using Helm

To improve database availability and fault tolerance, the single-instance MySQL setup was replaced with a production-ready, multi-replica configuration using Helm.

**Enhancements:**

* MySQL is deployed using the official **Bitnami Helm chart** with **3 replicas**.
* Kubernetes resources such as Secrets, ConfigMaps, and application deployments are orchestrated alongside the Helm release.
* All deployment steps are automated using the Ansible playbook:
  **`deploy-k8s-app-db-multiple-replicas.yaml`**

**Execution Flow:**

This playbook performs the following key tasks:

1. **Deploy NGINX Ingress Controller via Helm**

   * Ensures external traffic can reach the application through a managed LoadBalancer setup.

2. **Deploy MySQL Helm Chart (3 Replicas)**

   * Uses a templated `mysql-chart-values-lke.yaml.j2` file to define MySQL configuration with high availability and replication support.
   * Managed by Helm in the `default` namespace.

3. **Apply ConfigMap and Secrets**

   * A `db-configmap.yaml` is applied for non-sensitive configuration.
   * Sensitive values like MySQL credentials are rendered from a Vault-encrypted `db-secret.yaml.j2` template and applied securely.

4. **Deploy Docker Registry Secret**

   * Authenticates with Docker Hub using a base64-encoded `.dockerconfigjson` secret, enabling Kubernetes to pull private container images.

5. **Deploy Java Application and Ingress**

   * The Java app is deployed alongside the HA MySQL backend.
   * An ingress resource routes external HTTP traffic to the app via the ingress controller.

**Outcome:**

* A highly available MySQL deployment running with 3 pods ensures better fault tolerance and readiness for production load.
* The Java application continues to be accessible via:
  `http://<nginx-ingress-loadbalancer-address>`

---

### **EKS Cluster Setup (Common Prerequisite)**

Before executing the Phase 2 and Phase 3 deployment playbooks, ensure your environment is authenticated and connected to the correct EKS cluster.

```bash
# Set up kubeconfig for your EKS cluster
aws eks update-kubeconfig \
  --name <cluster-name> \
  --region <aws-region> \
  --kubeconfig <kubeconfig-file>

# Export to ensure Ansible, kubectl, and Helm use the correct config
export KUBECONFIG=<kubeconfig-file>
export K8S_AUTH_KUBECONFIG=$KUBECONFIG
```

This setup ensures:

* `kubectl` uses the correct kubeconfig.
* Ansible’s Kubernetes modules authenticate properly via `K8S_AUTH_KUBECONFIG`.
* Helm can talk to the cluster without additional config.

---

### Security Practices

To ensure sensitive data is handled securely throughout the automation process, **Ansible Vault** is used to encrypt all secrets and credentials, including:

* Database passwords
* SSH private keys
* Docker registry credentials
* Kubernetes secrets (when templated in Ansible)

**Best practices followed:**

* Encrypted secrets are stored in group-vars/vault.yaml.
* No hardcoded credentials exist in playbooks or templates.
* Vault is accessed at runtime using a password file or interactive prompt.
* Secrets are rendered dynamically into Kubernetes manifests, ensuring secrets are never committed in plaintext.
* This ensures that infrastructure automation remains secure, auditable, and production-ready while adhering to DevSecOps standards.

---

## Results

* Fully automated provisioning and deployment for both traditional and Kubernetes-based environments.
* Enhanced security and isolation, using private networking, IAM roles, and encrypted secrets via Ansible Vault.
* Seamless deployment workflows without manual steps.
* Scalable, resilient application infrastructure with minimal operational overhead.

---

## Tech Stack

* **Ansible** – Infrastructure provisioning and configuration management.
* **AWS (EC2, VPC, Subnets, NAT Gateway)** – Base infrastructure.
* **Java + MySQL** – Application stack.
* **Docker** – Application containerization.
* **Kubernetes** – Orchestration platform.
* **Helm** – Kubernetes package manager.
* **NGINX Ingress** – HTTP routing into Kubernetes.

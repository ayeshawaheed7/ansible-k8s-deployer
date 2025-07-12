# Java + MySQL Application Deployment: Traditional & Kubernetes-Based Automation

## Overview

This project automates the deployment of a Java web application backed by a MySQL database. It begins with a traditional virtual machine-based infrastructure on AWS and transitions into a modern, containerized Kubernetes setup. All provisioning and deployment tasks are automated using Ansible and Helm.

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

To modernize the deployment:

**Key Configurations:**

* The Java application is containerized and pushed to a Docker registry.
* Kubernetes manifests define:

  * **Deployments** and **Services** for Java and MySQL.
  * **ConfigMaps** and **Secrets** for managing environment-specific configuration.
* An **NGINX Ingress Controller** (deployed via Helm) enables browser-based access.
* An **Ingress** resource exposes the Java app at a defined HTTP endpoint.

**Automation:**

* All Kubernetes components are deployed using Ansible to simplify operations.

---

### Phase 3: High Availability MySQL Using Helm

To improve database reliability:

**Enhancement:**

* MySQL is deployed using a **Helm chart** with **3 replicas** for high availability.
* The single-instance MySQL setup is replaced with a production-ready, multi-pod configuration.
* Helm deployments are fully automated via Ansible.

---

## Results

* Fully automated provisioning and deployment for both traditional and Kubernetes-based environments.
* Improved security and isolation of the database layer.
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

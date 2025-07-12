# Java + MySQL Application Deployment: Traditional & Kubernetes-Based Automation

## Overview

This project automates the deployment of a Java web application backed by a MySQL database. It begins with a traditional virtual machine-based infrastructure on AWS and transitions into a modern, containerized Kubernetes setup. All provisioning and deployment tasks are automated using Ansible and Helm.

## Problem Statement

A robust and automated setup was required to deploy and manage a Java web application and its MySQL database on AWS. Initially, a traditional virtual machine–based setup without containers was used. Over time, the need emerged to:

* Automate the setup of infrastructure and applications from scratch.
* Secure the database by restricting external access.
* Enable reliable deployment of a Java web app and MySQL DB on AWS.
* Transition to Kubernetes for better maintainability and scalability.
* Improve database availability using a replicated setup.

## Solution Summary

The project is implemented in three key phases:

---

### Phase 1: Traditional Setup on AWS with Ansible

**Infrastructure:**

* Provisioned an **Ansible control node** in a public subnet.
* Created two EC2 instances within the same VPC:

  * A **web server** to host the Java application (with public access).
  * A **database server** to run MySQL (with **no public IP**).

**Automation:**

* Ansible playbooks provision and configure all EC2 instances.
* Tools are installed on the Ansible server and all necessary playbooks are copied to it.
* The MySQL database is installed using the official `geerlingguy.mysql` Ansible role.
* The Java application is deployed and exposed via `http://<web-server-ip>:8080`.

**Security:**

* The database server is placed in a **private subnet**.
* Internet access is routed through a **NAT Gateway**, ensuring isolation from direct public access.

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

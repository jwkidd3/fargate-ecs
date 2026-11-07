# Lab 1: Deploy Nginx on ECS Fargate via AWS Console

**Duration:** 50 minutes
**Difficulty:** Introductory
**Day:** 1
**Environment:** AWS Management Console (no terminal required)

---

## Learning Objectives

By the end of this lab, you will be able to:
- Create an ECS cluster configured for AWS Fargate
- Author a task definition that runs an Nginx container
- Create an Application Load Balancer with security groups and a target group
- Deploy an ECS service behind the ALB and access it through a stable DNS name
- Explain the relationship between clusters, task definitions, tasks, services, and load balancers

---

## Prerequisites

- AWS Management Console access
- Assigned username (user1, user2, user3, etc.)
- Basic understanding of containers and networking concepts

> **Note:** This lab is entirely console-based — you will not need a terminal.
> You build your Cloud9 workstation later, in [Lab 3](../lab03/README.md), where
> Terraform needs it.

---

## Exercise 1.1: Create an ECS Cluster

### Step 1 — Navigate to the ECS Console

1. In the AWS Management Console search bar, type **ECS** and select **Elastic Container Service**
2. You will land on the Amazon ECS dashboard

### Step 2 — Create a Cluster

1. In the left navigation pane, click **Clusters**
2. Click the **Create cluster** button

### Step 3 — Configure the Cluster

| Setting | Value |
|---------|-------|
| **Cluster name** | `userX-cluster` (replace X with your number, e.g., `user1-cluster`) |
| **Infrastructure** | **AWS Fargate (serverless)** |

> **Note:** Ensure only **AWS Fargate (serverless)** is selected under Infrastructure. Uncheck Amazon EC2 instances if it is checked.

### Step 4 — Create and Verify

1. Click **Create**
2. Wait for the cluster status to show **ACTIVE** (this typically takes 10-30 seconds)
3. Once active, click on your cluster name to explore the dashboard

### Step 5 — Explore the Cluster Dashboard

Take a moment to review the cluster dashboard tabs:
- **Services** — where your running services will appear
- **Tasks** — individual running task instances
- **Infrastructure** — shows the Fargate capacity provider
- **Metrics** — CPU and memory utilization (empty for now)

---

## Exercise 1.2: Create a Task Definition

A task definition is a blueprint that tells ECS how to run your container. Think of it as a recipe that specifies the Docker image, CPU, memory, ports, and other settings.

### Step 1 — Navigate to Task Definitions

1. In the left navigation pane, click **Task definitions**
2. Click **Create new task definition**

### Step 2 — Configure Task Definition

| Setting | Value |
|---------|-------|
| **Task definition family** | `userX-task` (replace X with your number, e.g., `user1-task`) |
| **Launch type** | **AWS Fargate** |
| **Operating system/Architecture** | **Linux/X86_64** |
| **Task role** | None |
| **Task execution role** | **ecsTaskExecutionRole** |
| **CPU** | **.5 vCPU** |
| **Memory** | **1 GB** |

> **Note:** The **Task execution role** (`ecsTaskExecutionRole`) allows ECS to pull container images and write logs on your behalf. If this role does not appear in the dropdown, ask your instructor for assistance.

### Step 3 — Add a Container

In the **Container - 1** section, configure:

| Setting | Value |
|---------|-------|
| **Name** | `userX-container` (replace X with your number, e.g., `user1-container`) |
| **Image URI** | `nginx:latest` |
| **Essential container** | Yes |
| **Container port** | `80` |
| **Protocol** | **TCP** |

Leave all other container settings at their defaults.

### Step 4 — Create and Review

1. Click **Create**
2. You should see a success message confirming the task definition was created
3. Click on the task definition name to view its details
4. Click the **JSON** tab to review the full task definition in JSON format

> **Tip:** The JSON representation is useful for understanding exactly what ECS will use when launching your container. In later labs, you will author task definitions directly in Terraform.

---

## Exercise 1.3: Create the Application Load Balancer

Before deploying the ECS service, you will create an Application Load Balancer (ALB) to provide a stable DNS endpoint and distribute traffic to your containers. This is the standard production pattern — containers should sit behind a load balancer rather than being accessed directly by IP.

### Step 1 — Create a Security Group for the ALB

1. Navigate to the **EC2 Console**
2. In the left sidebar, click **Security Groups**
3. Click **Create security group**
4. Configure:

| Setting | Value |
|---------|-------|
| **Security group name** | `userX-alb-sg` |
| **Description** | `ALB security group for userX` |
| **VPC** | Default |

5. Add an **Inbound Rule**:

| Type | Protocol | Port Range | Source |
|------|----------|------------|--------|
| HTTP | TCP | 80 | `0.0.0.0/0` |

6. **Outbound Rule** — leave the default (All traffic, `0.0.0.0/0`)
7. Click **Create security group**

### Step 2 — Create a Security Group for ECS Tasks

1. Click **Create security group** again
2. Configure:

| Setting | Value |
|---------|-------|
| **Security group name** | `userX-ecs-sg` |
| **Description** | `ECS security group for userX` |
| **VPC** | Default |

3. Add an **Inbound Rule**:

| Type | Protocol | Port Range | Source |
|------|----------|------------|--------|
| Custom TCP | TCP | 80 | Select `userX-alb-sg` (the ALB security group you just created) |

4. **Outbound Rule** — leave the default (All traffic, `0.0.0.0/0`)
5. Click **Create security group**

> **Note:** The ECS security group only allows inbound traffic **from the ALB security group** — not from the open internet. This means containers can only be reached through the load balancer, which is a security best practice.

### Step 3 — Navigate to Load Balancers

1. In the EC2 Console left sidebar, click **Load Balancers**
2. Click **Create Load Balancer**
3. Under **Application Load Balancer**, click **Create**

### Step 4 — Configure Basic Settings

| Setting | Value |
|---------|-------|
| **Name** | `userX-alb` |
| **Scheme** | Internet-facing |
| **IP address type** | IPv4 |
| **VPC** | Default |
| **Mappings** | Select **at least 2** Availability Zones |

### Step 5 — Attach the ALB Security Group

1. In the **Security groups** section, click the refresh icon
2. Select `userX-alb-sg`
3. **Remove** the default security group so only `userX-alb-sg` is attached

### Step 6 — Create a Target Group

1. In the **Listeners and routing** section, click **Create target group** (opens in a new tab)
2. Configure the target group:

| Setting | Value |
|---------|-------|
| **Target type** | IP addresses |
| **Target group name** | `userX-target-group` |
| **Protocol** | HTTP |
| **Port** | 80 |
| **VPC** | Default |
| **Health check path** | `/` |

3. Click **Next**
4. Do **not** register any targets manually — ECS will handle this automatically
5. Click **Create target group**

### Step 7 — Configure the Listener

1. Return to the ALB creation tab
2. Under **Listeners and routing**, configure:

| Setting | Value |
|---------|-------|
| **Protocol** | HTTP |
| **Port** | 80 |
| **Default action** | Forward to `userX-target-group` |

3. Click the refresh icon next to the target group dropdown if your new target group is not visible

### Step 8 — Create the ALB

1. Review all settings
2. Click **Create load balancer**
3. Wait for the ALB state to change from **Provisioning** to **Active** (this may take 2-3 minutes)
4. Once active, copy the **DNS name** — you will use it to test your service

> **Save the ALB DNS name.** It looks like `userX-alb-123456789.us-east-1.elb.amazonaws.com`. You will need it shortly.

---

## Exercise 1.4: Deploy an ECS Service

Now you will create an ECS service that runs your Nginx task behind the Application Load Balancer.

### Step 1 — Navigate to Your Cluster

1. Return to the **ECS Console**: [https://console.aws.amazon.com/ecs](https://console.aws.amazon.com/ecs)
2. In the left navigation pane, click **Clusters**
3. Click on **userX-cluster** (your cluster)
4. Click the **Services** tab
5. Click **Create**

### Step 2 — Configure the Service

| Setting | Value |
|---------|-------|
| **Launch type** | **FARGATE** |
| **Task definition** | `userX-task` (select the Family, use LATEST revision) |
| **Service name** | `userX-service` (replace X with your number, e.g., `user1-service`) |
| **Desired tasks** | `1` |

### Step 3 — Configure Load Balancing

Expand the **Load balancing** section and configure:

| Setting | Value |
|---------|-------|
| **Load balancer type** | Application Load Balancer |
| **Application Load Balancer** | Select `userX-alb` |
| **Container** | `userX-container : 80 : 80` |
| **Target group** | Use an existing target group |
| **Target group name** | `userX-target-group` |

### Step 4 — Configure Networking

In the **Networking** section:

| Setting | Value |
|---------|-------|
| **VPC** | Default |
| **Subnets** | Select public subnets (same AZs as your ALB) |
| **Security group** | Select existing: `userX-ecs-sg` |
| **Auto-assign public IP** | **ENABLED** |

> **Note:** Remove the default security group if it is selected. Only `userX-ecs-sg` should be attached.

### Step 5 — Create the Service

1. Click **Create**
2. Wait for the service deployment to begin
3. You will be redirected to the service detail page

---

## Exercise 1.5: Verify and Explore

### Step 1 — Check Task Status

1. On your service page, click the **Tasks** tab
2. You should see one task listed
3. Wait for the **Last status** column to show **RUNNING** (this may take 1-2 minutes while Fargate pulls the Nginx image and starts the container)

> **Note:** The task will transition through states: **PROVISIONING** -> **PENDING** -> **RUNNING**

### Step 2 — Verify Healthy Targets

1. Navigate to **EC2 Console** > **Target Groups** > `userX-target-group`
2. Click the **Targets** tab
3. Wait for the target status to show **healthy** (this may take 1-2 minutes after the task reaches RUNNING)

### Step 3 — Access Nginx Through the ALB

1. Navigate to **EC2 Console** > **Load Balancers** > `userX-alb`
2. Copy the **DNS name** from the **Description** tab
3. Open a new browser tab and paste the DNS name, prefixed with `http://`

```
http://userX-alb-123456789.us-east-1.elb.amazonaws.com
```

You should see the **Welcome to nginx!** default page.

> **Note:** Use `http://`, not `https://` — the listener you created only serves
> port 80. If you get a `503 Service Temporarily Unavailable`, wait 30-60 seconds
> for the target to pass its health check, then reload.

### Step 4 — Explore the Logs Tab

1. Go back to the ECS Console and navigate to your running task
2. Click the **Logs** tab
3. You should see Nginx access logs, including the health check requests from the ALB (`ELB-HealthChecker/2.0`) and the page load from your browser
4. These logs are streamed from the container's stdout/stderr via Amazon CloudWatch Logs

### Step 5 — Explore the Events Tab

1. Navigate back to your service (click the service name in the breadcrumb)
2. Click the **Events** tab
3. Review the event history — you should see entries such as:
   - "service userX-service has reached a steady state"
   - "service userX-service has started 1 tasks"
   - "service userX-service registered 1 targets in target-group userX-target-group"

---

## Lab Summary

### What You Accomplished

- Created an **ECS cluster** configured for AWS Fargate
- Authored a **task definition** specifying the Nginx container, CPU, and memory
- Created **two security groups** with a least-privilege traffic model (ALB public, ECS private)
- Created an **Application Load Balancer** with a target group and HTTP listener
- Deployed an **ECS service** behind the ALB
- Verified the deployment by accessing Nginx through the ALB DNS name
- Explored ECS console features including logs, events, and task details
- Understood the **ECS object model:** cluster, task definition, service, task, ALB

---

## Troubleshooting

### Task stays in PROVISIONING and never reaches RUNNING

- Check the **security group** attached to the service — ensure `userX-ecs-sg` allows inbound TCP on port 80 from `userX-alb-sg`
- Verify the **subnet** has internet access (it must be a public subnet with an internet gateway)
- Confirm **Auto-assign public IP** is set to ENABLED
- Check the **Events** tab on the service for error messages

### ALB returns 503 Service Temporarily Unavailable

- The task may not have passed its health check yet — wait 30-60 seconds and try again
- Navigate to **EC2 Console** > **Target Groups** > `userX-target-group` > **Targets** tab to check target health
- Verify the ECS security group allows inbound traffic from the ALB security group

### ALB Shows Unhealthy Targets

- Verify the ECS security group (`userX-ecs-sg`) has an inbound rule allowing HTTP (port 80) from `userX-alb-sg`
- Confirm the health check path is `/` in the target group settings
- Check that the task is in RUNNING status in the ECS Console

### Cannot access the ALB DNS name in the browser

- Make sure you are using `http://` and not `https://` in the browser URL bar
- Verify the ALB state is **Active** (not Provisioning) in the EC2 Console
- Check the ALB security group (`userX-alb-sg`) has an inbound rule for HTTP from `0.0.0.0/0`

### Task immediately stops after reaching RUNNING

- Click on the stopped task and check the **Logs** tab for error output
- Verify the container image is exactly `nginx:latest` (check for typos)
- Ensure the **Task execution role** is set to `ecsTaskExecutionRole` so ECS can pull the image
- Check that the container port is set to **80** (not a different port)

---

## Appendix: Understanding What You Deployed

> **Take-home reading.** This section is not part of the timed lab. Read it after
> class to consolidate what you built, or during the day if you finish early.

### Architecture Overview

Here is what you just built:

```
                   ┌─────────┐
                   │ Internet│
                   │ (You!)  │
                   └────┬────┘
                        │ HTTP :80
                        ▼
┌──────────────────────────────────────────────────────────┐
│                      AWS Cloud                            │
│                                                          │
│   ┌────────────────────────────────────────────────┐     │
│   │   Application Load Balancer (userX-alb)        │     │
│   │   Security Group: userX-alb-sg (0.0.0.0/0:80) │     │
│   └────────────────────┬───────────────────────────┘     │
│                        │                                  │
│   ┌────────────────────▼───────────────────────────┐     │
│   │          ECS Cluster (userX-cluster)            │     │
│   │                                                │     │
│   │   ┌────────────────────────────────────────┐   │     │
│   │   │      ECS Service (userX-service)       │   │     │
│   │   │                                        │   │     │
│   │   │   ┌────────────────────────────────┐   │   │     │
│   │   │   │   Fargate Task                 │   │   │     │
│   │   │   │   Security Group: userX-ecs-sg │   │   │     │
│   │   │   │                                │   │   │     │
│   │   │   │   ┌────────────────────────┐   │   │   │     │
│   │   │   │   │  nginx:latest          │   │   │   │     │
│   │   │   │   │  (userX-container)     │   │   │   │     │
│   │   │   │   │  Port 80               │   │   │   │     │
│   │   │   │   └────────────────────────┘   │   │   │     │
│   │   │   │                                │   │   │     │
│   │   │   └────────────────────────────────┘   │   │     │
│   │   │                                        │   │     │
│   │   └────────────────────────────────────────┘   │     │
│   │                                                │     │
│   └────────────────────────────────────────────────┘     │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### Security Model

Traffic flows through two security groups:

1. **`userX-alb-sg`** — allows inbound HTTP (port 80) from anywhere on the internet
2. **`userX-ecs-sg`** — allows inbound HTTP (port 80) **only from the ALB security group**

This means the internet can reach the ALB, but cannot directly reach your containers. All traffic must pass through the load balancer.

### Key Concepts Recap

| Concept | What It Is | Your Value |
|---------|-----------|------------|
| **Cluster** | A logical grouping of tasks and services. It provides the infrastructure boundary for your workloads. | `userX-cluster` |
| **Task Definition** | A blueprint (like a Docker Compose file) that specifies which container image to run, how much CPU/memory to allocate, and what ports to expose. | `userX-task` |
| **Task** | A running instance of a task definition. This is the actual container running on Fargate compute. | The running Nginx container |
| **Service** | A long-running controller that ensures the desired number of tasks are always running. If a task crashes, the service replaces it. | `userX-service` |
| **ALB** | An Application Load Balancer distributes HTTP traffic across tasks and provides a stable DNS endpoint. | `userX-alb` |
| **Target Group** | Tracks the IP addresses of healthy tasks so the ALB knows where to send traffic. | `userX-target-group` |

### How These Concepts Connect

1. You created a **Cluster** as the home for your workloads
2. You wrote a **Task Definition** describing your Nginx container
3. You created an **ALB** with security groups and a target group to handle incoming traffic
4. You created a **Service** that launched a **Task** and registered it with the target group
5. The **ALB** routes internet traffic to your container through the target group
6. The **Service** monitors the task and will restart it if it ever fails
7. **Fargate** handled all server provisioning — you never managed an EC2 instance

---

## Next Steps

In **Lab 2**, you will:
- **Scale** the service to multiple tasks and observe the ALB distributing traffic
- **Explore CloudWatch Logs** to see container output and health check activity
- **Clean up** all console-created resources in preparation for the Terraform labs

**Well done — you have deployed your first container on AWS Fargate behind a load balancer!**

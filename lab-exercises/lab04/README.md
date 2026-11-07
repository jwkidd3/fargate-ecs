# 🚀 Lab 4: Deploy ECS Fargate with Terraform

| | |
|---|---|
| **Duration** | 40 minutes |
| **Level** | Introductory |
| **Environment** | AWS Cloud9 on Amazon Linux 2 (built in Lab 3) |
| **Goal** | Deploy a fully functional ECS Fargate service using a pre-built Terraform configuration |
| **Prerequisite** | Lab 3 completed (Terraform installed) |

---

## 📋 Overview

In this lab you will deploy an ECS Fargate service running Nginx behind an Application Load Balancer -- entirely through Terraform. The `main.tf` file in this directory contains all the infrastructure definitions. You will review the configuration, customize it with your assigned username, deploy it, and verify everything is running.

> **Note:** This lab deploys the same architecture pattern you built manually in Labs 1 and 2 (cluster, task definition, ALB, service), but now defined as Infrastructure as Code. The initial task size starts smaller (0.25 vCPU / 0.5 GB) — you will scale it up in Lab 5.

---

## 🔍 Exercise 4.1: Navigate and Review the Configuration

### Step 1 -- Navigate to the Lab Directory

```bash
cd ~/environment/fargate-ecs/lab-exercises/lab04
```

### Step 2 -- View the Terraform Configuration

```bash
cat main.tf
```

### Step 3 -- Understand Each Resource

Take a few minutes to read through `main.tf`. The following table maps every resource in the file to its purpose:

| Resource | Terraform Type | Purpose | Name Pattern |
|----------|---------------|---------|--------------|
| Required Providers | `terraform` block | Pin AWS provider to version ~> 5.0 | N/A |
| Provider | `provider "aws"` | Set region to `us-east-1` | N/A |
| Default VPC | `data "aws_vpc"` | Look up the existing default VPC | N/A |
| Default Subnets | `data "aws_subnets"` | Look up existing subnets in the default VPC | N/A |
| ECS Execution Role | `data "aws_iam_role"` | Look up the pre-existing `ecsTaskExecutionRole` IAM role | N/A |
| ECS Cluster | `aws_ecs_cluster` | Container orchestration cluster | `user0-cluster` |
| ALB Security Group | `aws_security_group` | Allow inbound HTTP (port 80) traffic to the ALB | `user0_ALB` |
| ECS Security Group | `aws_security_group` | Allow traffic from the ALB security group to ECS tasks | `user0_ECS` |
| ALB | `aws_lb` | Internet-facing Application Load Balancer | `user0-alb` |
| Target Group | `aws_lb_target_group` | Route traffic to Fargate task IPs (target type `ip`) | `user0-target-group` |
| Listener | `aws_lb_listener` | Listen on port 80 and forward to the target group | N/A |
| Task Definition | `aws_ecs_task_definition` | Nginx container blueprint (256 CPU / 512 MiB memory, Fargate) | `user0-task` |
| ECS Service | `aws_ecs_service` | Run and maintain desired count of tasks behind the ALB | `user0-service` |

### Key Observations

- **Data sources** (`data` blocks) look up existing AWS resources rather than creating new ones.
- The ECS security group only allows inbound traffic **from the ALB security group** -- not from the open internet. This is a security best practice.
- The `depends_on` in the ECS service ensures the ALB listener exists before tasks try to register.
- The task definition uses `awsvpc` network mode, which is **required** for Fargate and gives each task its own ENI.

---

## ✏️ Exercise 4.2: Customize the Configuration

Every resource in `main.tf` uses the prefix `user0`. You must replace this with your assigned username to avoid naming collisions with other students.

### Step 1 -- Replace All Occurrences

Replace `X` below with your assigned user number:

```bash
sed -i 's/user0/userX/g' main.tf
```

For example, if you are **user3**:

```bash
sed -i 's/user0/user3/g' main.tf
```

### Step 2 -- Verify the Replacements

```bash
grep 'userX' main.tf
```

You should see your username prefix on the cluster name, both security groups, the ALB, target group, task definition family, container name, and ECS service name.

### Step 3 -- Confirm No `user0` Remains

```bash
grep 'user0' main.tf
```

This command should return **no output**. If it does return matches, re-run the `sed` command with the correct username.

---

## 🏗️ Exercise 4.3: Deploy with Terraform

### Step 1 -- Initialize Terraform

```bash
terraform init
```

This downloads the AWS provider plugin (~5.x) and sets up the working directory. You should see "Terraform has been successfully initialized!" in the output.

### Step 2 -- Preview the Execution Plan

```bash
terraform plan
```

Review the output carefully. You should see approximately **8 resources to add**:

- 1 ECS cluster
- 2 security groups
- 1 ALB
- 1 target group
- 1 listener
- 1 task definition
- 1 ECS service

> **Tip:** The `data` sources are read operations and do not count toward "resources to add."

### Step 3 -- Apply the Configuration

```bash
terraform apply
```

When prompted, type `yes` and press Enter.

Watch the output as Terraform creates each resource. The deployment typically takes **2-4 minutes**, with the ALB and ECS service taking the longest.

### Step 4 -- Retrieve the ALB DNS Name

```bash
terraform state show aws_lb.alb | grep dns_name
```

Copy the DNS name -- you will use it in the next exercise.

---

## ✅ Exercise 4.4: Verify the Deployment

### Step 1 -- Test with curl

Store the ALB DNS name in a variable and test:

```bash
ALB_DNS=$(terraform state show aws_lb.alb | grep "dns_name" | head -1 | awk '{print $3}' | tr -d '"')
curl http://$ALB_DNS
```

> **Note:** The ALB target group health checks may take **1-2 minutes** to mark the task as healthy. If you get a `503 Service Temporarily Unavailable` response, wait 60 seconds and try again.

You should see the default **Nginx welcome page** HTML.

### Step 2 -- Test in a Browser

Open a new browser tab and paste the ALB DNS name (the `http://` URL). You should see the Nginx welcome page.

### Step 3 -- Verify in the AWS ECS Console

1. Open the **ECS Console**: [https://console.aws.amazon.com/ecs](https://console.aws.amazon.com/ecs)
2. Confirm your cluster (e.g., `user3-cluster`) appears in the cluster list
3. Click into your cluster and verify:
   - **Services tab:** Your service shows `1/1` running tasks
   - **Tasks tab:** One task in `RUNNING` status
4. Click on the running task to inspect its details (ENI, private IP, container status)

---

## 🔎 Exercise 4.5: Explore Terraform State

Terraform tracks every resource it manages in a **state file**. Let's explore it.

### Step 1 -- List All Managed Resources

```bash
terraform state list
```

You should see entries like:

```
data.aws_iam_role.ecs_execution_role
data.aws_subnets.default
data.aws_vpc.default
aws_ecs_cluster.main
aws_ecs_service.nginx_service
aws_ecs_task_definition.nginx
aws_lb.alb
aws_lb_listener.listener
aws_lb_target_group.tg
aws_security_group.alb_sg
aws_security_group.ecs_sg
```

### Step 2 -- Inspect Individual Resources

```bash
terraform state show aws_ecs_cluster.main
```

Note the cluster ARN, name, and other attributes Terraform recorded.

```bash
terraform state show aws_ecs_service.nginx_service
```

Observe the service configuration including `desired_count`, `launch_type`, `network_configuration`, and the `load_balancer` block.

> **In production**, `terraform.tfstate` is stored remotely (for example in S3
> with DynamoDB locking) so a whole team can share one source of truth. Here it
> sits in your lab directory.

---

## 🎉 Success

You have successfully deployed an ECS Fargate service running Nginx behind an Application Load Balancer using Terraform.

> **IMPORTANT: Do NOT run `terraform destroy` yet. Lab 5 continues working with these resources.**

---

## 🔧 Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| `ClusterAlreadyExistsException` | A cluster with this name already exists (likely from Lab 2) | Verify Lab 2 cleanup is complete, or change the cluster name in `main.tf` to something unique |
| `InvalidGroup.Duplicate` | A security group with this name already exists | Delete the leftover security group from the EC2 Console > Security Groups, then re-run `terraform apply` |
| ALB returns `503 Service Temporarily Unavailable` | Task has not yet registered as healthy in the target group | Wait 1-2 minutes for the health check to pass, then retry |
| `terraform init` fails with network error | Cloud9 network connectivity issue | Check your internet connection; try running `terraform init` again |
| `No valid credential sources found` | AWS credentials not configured | In Cloud9 this should be automatic; verify by running `aws sts get-caller-identity` |

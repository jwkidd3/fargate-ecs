# Bonus Lab: Write a Terraform Resource — CloudWatch Log Group

**Duration:** 30 minutes
**Difficulty:** Introductory
**Prerequisite:** Lab 4 completed (resources deployed), or re-deploy Lab 4 first

---

## Overview

In Labs 4 and 5 you customized a pre-built `main.tf` with `sed` but never wrote Terraform from scratch. In this exercise you will author new Terraform resources by hand: a CloudWatch Logs log group and the `logConfiguration` block that wires container output into it. When finished, your Nginx container logs will stream to a dedicated log group that you defined in code.

---

## Exercise 1: Add a CloudWatch Log Group Resource

### Step 1 — Navigate to the Lab 4 Directory

```bash
cd ~/environment/fargate-ecs/lab-exercises/lab04
```

If you previously destroyed your Lab 4/5 resources, redeploy them first:

```bash
terraform init
terraform apply
```

### Step 2 — Add the Log Group Resource

Open `main.tf` in the Cloud9 editor. Add the following resource **above** the task definition resource (`aws_ecs_task_definition`):

```hcl
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/userX-task"
  retention_in_days = 7
}
```

> **Note:** Replace `userX` with your assigned username (e.g., `user1`, `user2`). The `retention_in_days` setting automatically deletes logs older than 7 days, which prevents unbounded storage costs.

### Step 3 — Understand What You Wrote

| Attribute | Value | Purpose |
|-----------|-------|---------|
| `name` | `/ecs/userX-task` | The log group name — follows the `/ecs/<family>` convention |
| `retention_in_days` | `7` | Auto-delete logs after 7 days |

This is the same type of log group that ECS creates automatically when you use the console, but now **you** control it through code — including its retention policy.

---

## Exercise 2: Wire the Log Group into the Task Definition

### Step 1 — Add logConfiguration to the Container Definition

In `main.tf`, locate the `container_definitions` block inside the task definition. You need to add a `logConfiguration` block to the container object.

Find this section:

```hcl
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
```

Add the following **after** the `portMappings` block (still inside the container object):

```hcl
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/userX-task"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
```

> **Note:** Replace `userX` with your assigned username. The `awslogs-group` value must match the `name` of the log group resource you created in Exercise 1.

### Step 2 — Review the Full Container Definition

Your `container_definitions` block should now look like this:

```hcl
  container_definitions = jsonencode([
    {
      name      = "userX-container"
      image     = "nginx:latest"
      cpu       = 256
      memory    = 512
      essential = true

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/userX-task"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
```

---

## Exercise 3: Deploy and Verify

### Step 1 — Preview the Changes

```bash
terraform plan
```

You should see:

- **1 to add** — the new CloudWatch log group
- **1 to change** (forces replacement) — the task definition (a new revision is created because `container_definitions` changed)
- **1 to change** (in-place) — the ECS service (updated to reference the new task definition revision)

### Step 2 — Apply

```bash
terraform apply
```

Type **yes** when prompted. ECS will perform a rolling deployment with the new task definition.

### Step 3 — Verify the Log Group in the Console

1. Open the **CloudWatch Console**: [https://console.aws.amazon.com/cloudwatch](https://console.aws.amazon.com/cloudwatch)
2. In the left sidebar, expand **Logs** and click **Log groups**
3. Find `/ecs/userX-task` in the list
4. Confirm it exists and shows a **Retention** of `7 days`

### Step 4 — Verify Container Logs Are Flowing

1. Click on the `/ecs/userX-task` log group
2. You should see one or more **log streams** (one per running task)
3. Click on a log stream — you should see nginx access logs including ALB health check entries (`ELB-HealthChecker/2.0`)

### Step 5 — Generate Some Log Entries

```bash
ALB_DNS=$(terraform state show aws_lb.alb | grep "dns_name" | head -1 | awk '{print $3}' | tr -d '"')
for i in 1 2 3 4 5; do
  curl -s http://$ALB_DNS > /dev/null
done
```

Return to the CloudWatch log stream and refresh — you should see your `curl` requests logged.

### Step 6 — Verify in Terraform State

```bash
terraform state list
```

You should see `aws_cloudwatch_log_group.ecs_logs` in the list alongside the other resources.

```bash
terraform state show aws_cloudwatch_log_group.ecs_logs
```

Review the attributes Terraform recorded, including the ARN and retention setting.

---

## Exercise 4: Clean Up (if finished with all bonus labs)

If you are done with all bonus labs, destroy everything:

```bash
terraform destroy
```

Type **yes** when prompted. Terraform will remove the log group along with all other resources.

---

## What You Learned

- How to **write a Terraform resource** from scratch (not just customize with `sed`)
- How CloudWatch log groups work with ECS Fargate via the `awslogs` driver
- How `logConfiguration` in a container definition connects a container to a log group
- That changing `container_definitions` forces a new task definition revision and rolling deployment
- How to verify Terraform-managed resources in both the AWS Console and Terraform state

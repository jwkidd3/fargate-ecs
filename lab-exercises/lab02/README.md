# Lab 2: Scaling, Logging, and Cleanup

**Duration:** 30 minutes
**Difficulty:** Introductory
**Day:** 1
**Environment:** AWS Cloud9

---

## Overview

In this lab you will scale your ECS Fargate service to multiple tasks, observe the ALB distributing traffic, examine container logs in CloudWatch, and then perform a full manual cleanup of every resource you created in Labs 1 and 2. The cleanup exercise is mandatory — the afternoon Terraform labs require a clean account with no naming conflicts.

### What You Will Accomplish

- Scale the ECS service to multiple tasks and observe traffic distribution
- Explore container logs in CloudWatch
- Tear down all console-created resources in the correct dependency order

---

## Prerequisites

- Completed **Lab 1** (all resources still deployed: cluster, task definition, ALB, service)
- AWS Cloud9 environment open and connected
- Your unique student prefix (referred to as `userX` throughout this lab)

---

## Exercise 2.1: Scale the Service

Scaling a Fargate service is as simple as changing the desired task count. The ALB automatically distributes traffic to all healthy tasks.

### Step 1 — Increase the Desired Count

1. Navigate to **ECS Console** > **Clusters** > `userX-cluster`
2. Select the **Services** tab
3. Select `userX-service`
4. Click **Update**
5. Change **Desired tasks** from `1` to `3`
6. Click **Update**

### Step 2 — Observe Task Provisioning

1. Click the **Tasks** tab
2. Watch as new tasks move through the lifecycle: **PROVISIONING** -> **PENDING** -> **RUNNING**
3. All 3 tasks should reach **RUNNING** within 1-2 minutes

### Step 3 — Verify Target Registration

1. Navigate to **EC2 Console** > **Target Groups** > `userX-target-group`
2. Click the **Targets** tab
3. Confirm that **3 targets** are registered and in a **healthy** state (this may take 1-2 minutes)

### Step 4 — Test Load Balancing

Run multiple requests from your Cloud9 terminal to observe traffic distribution:

```bash
for i in {1..10}; do
  curl -s -o /dev/null -w "Request $i: HTTP %{http_code}\n" http://userX-alb-123456789.us-east-1.elb.amazonaws.com
done
```

> **Note:** Replace the URL with your actual ALB DNS name from Lab 1.

All 10 requests should return `HTTP 200`. The ALB distributes these across your 3 tasks using a round-robin algorithm.

---

## Exercise 2.2: Explore CloudWatch Logs

The task definition from Lab 1 uses the **awslogs** log driver, which sends container stdout/stderr to CloudWatch Logs automatically.

### Step 1 — Navigate to Log Groups

1. Open the **CloudWatch Console**
2. In the left sidebar, expand **Logs** and click **Log groups**
3. Find the log group associated with your task definition (e.g., `/ecs/userX-task`)

### Step 2 — View Log Streams

1. Click on your log group
2. You will see **one log stream per running task** — you should see 3 streams (one for each of the scaled tasks)
3. Click on any log stream to view its contents

### Step 3 — Examine Nginx Access Logs

1. Inside a log stream, you will see nginx access log entries
2. Each entry shows the request from the ALB health check (`ELB-HealthChecker/2.0`) and any `curl` requests you made
3. Example log line:

```
10.0.1.50 - - [22/Feb/2026:14:30:00 +0000] "GET / HTTP/1.1" 200 615 "-" "curl/7.88.1"
```

### Step 4 — Understand the awslogs Driver Configuration

The awslogs driver was configured in your task definition with these parameters:

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `awslogs-group` | `/ecs/userX-task` | CloudWatch log group name |
| `awslogs-region` | `us-east-1` | Region for CloudWatch |
| `awslogs-stream-prefix` | `ecs` | Prefix for log stream names |

> **Note:** The awslogs driver is the simplest logging option for ECS Fargate. In production, you might use FireLens (Fluent Bit) for more advanced routing and filtering.

---

## Exercise 2.3: Clean Up All Console Resources (MANDATORY)

> **You must clean up ALL resources before the Terraform labs this afternoon. Leaving resources running will cause naming conflicts and Terraform errors. Do not skip this exercise.**

Resource deletion must follow the correct dependency order. Deleting resources out of order will fail because of cross-references between them.

### Step 1 — Delete the ECS Service

1. Navigate to **ECS Console** > **Clusters** > `userX-cluster`
2. Select `userX-service`
3. Click **Update**, set **Desired tasks** to `0`, click **Update**
4. Wait for all tasks to stop (task count = 0 on the Tasks tab)
5. Select `userX-service` again and click **Delete**
6. Confirm deletion

### Step 2 — Wait for All Tasks to Stop

1. Click the **Tasks** tab on your cluster
2. Verify that **no tasks** are running or stopping
3. This may take 1-2 minutes — **do not proceed until the count is 0**

### Step 3 — Deregister the Task Definition

1. Navigate to **ECS Console** > **Task Definitions**
2. Click on `userX-task`
3. Select **all revisions**
4. Click **Actions** > **Deregister**
5. Confirm — the task definition status changes to **INACTIVE**

### Step 4 — Delete the ECS Cluster

1. Navigate to **ECS Console** > **Clusters**
2. Select `userX-cluster`
3. Click **Delete cluster**
4. Confirm by typing `delete userX-cluster` when prompted

### Step 5 — Delete the Application Load Balancer

1. Navigate to **EC2 Console** > **Load Balancers**
2. Select `userX-alb`
3. Click **Actions** > **Delete load balancer**
4. Confirm by typing `confirm` when prompted

### Step 6 — Delete the Target Group

1. Navigate to **EC2 Console** > **Target Groups**
2. Select `userX-target-group`
3. Click **Actions** > **Delete**
4. Confirm deletion

### Step 7 — Delete Security Groups

1. Navigate to **EC2 Console** > **Security Groups**
2. Delete the **ECS security group** first: select `userX-ecs-sg` > **Actions** > **Delete security groups** > Confirm
3. Delete the **ALB security group**: select `userX-alb-sg` > **Actions** > **Delete security groups** > Confirm

> **Note:** If a security group deletion fails with a "dependency violation" error, it means ENIs are still attached from recently stopped tasks. Wait 2-3 minutes and try again.

### Step 8 — Verify All Resources Are Removed

Perform a final check across each console:

| Console | Check | Expected |
|---------|-------|----------|
| **ECS** > Clusters | No `userX-cluster` | Empty or no matching clusters |
| **ECS** > Task Definitions | `userX-task` shows INACTIVE | No active definitions |
| **EC2** > Load Balancers | No `userX-alb` | Empty or no matching ALBs |
| **EC2** > Target Groups | No `userX-target-group` | Empty or no matching TGs |
| **EC2** > Security Groups | No `userX-alb-sg` or `userX-ecs-sg` | Only default SG remains |
| **CloudWatch** > Log Groups | `/ecs/userX-task` may remain | OK to leave — no cost impact |

> **If any resources remain, delete them now. The Terraform labs in the afternoon will create resources with similar names and will fail if duplicates exist.**

---

## Lab Summary

### Completion Checklist

- [ ] Scaled the service to 3 tasks
- [ ] Verified 3 healthy targets in the target group
- [ ] Tested load balancing across multiple tasks
- [ ] Explored CloudWatch log groups and log streams
- [ ] Examined nginx access logs and health check entries
- [ ] Deleted ECS service and waited for tasks to drain
- [ ] Deregistered task definition
- [ ] Deleted ECS cluster
- [ ] Deleted ALB and target group
- [ ] Deleted both security groups
- [ ] Verified all resources are removed

### Key Observation

Notice how many manual steps were required to clean up these resources — and in a specific dependency order. Forgetting a single step leaves orphaned resources that cost money and cause conflicts. **This is exactly the problem that Infrastructure as Code solves.** In the afternoon Terraform labs, a single `terraform destroy` command will handle all of this automatically, in the correct order, every time.

---

## Next Steps

In the afternoon Terraform labs, you will:
- **Lab 3**: Install Terraform on your Cloud9 environment and verify it works with AWS
- **Lab 4**: Deploy the **same ECS Fargate architecture** from Labs 1 and 2 — but entirely through code with a single `terraform apply`
- **Lab 5**: Scale, modify, and destroy your infrastructure with simple code changes

> **Keep your Cloud9 environment open.** You will continue using it for the Terraform labs this afternoon.

---

## Troubleshooting

### Cannot Delete ECS Cluster

- **Cause:** Active services or tasks still exist in the cluster
- **Fix:** Delete all services first (set desired count to 0, wait for tasks to drain, then delete the service). Deregister task definitions. Then retry cluster deletion.

### Security Group Deletion Fails with Dependency Violation

- **Cause:** Elastic Network Interfaces (ENIs) from recently stopped Fargate tasks are still attached
- **Fix:** Wait 2-3 minutes for the ENIs to fully detach, then retry. You can check **EC2** > **Network Interfaces** and filter by the security group to monitor progress.

### 503 Service Temporarily Unavailable from ALB

- **Cause:** No healthy targets registered yet — tasks are still starting or have not passed the health check
- **Fix:** Wait 30-60 seconds for the task to start and pass the health check. Monitor the target health in **EC2** > **Target Groups** > **Targets**.

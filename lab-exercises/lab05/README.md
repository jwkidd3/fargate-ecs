# 🔄 Lab 5: Modify, Scale, and Destroy with Terraform

| | |
|---|---|
| **Duration** | 42 minutes |
| **Level** | Introductory |
| **Environment** | AWS Cloud9 on Amazon Linux 2 (built in Lab 3) |
| **Prerequisite** | Lab 4 completed successfully (resources still deployed) |
| **Goal** | Scale an ECS service, modify task resources, and perform a clean teardown -- all with Terraform |

---

## 📋 Overview

In Lab 4 you deployed a complete ECS Fargate environment with a single `terraform apply`. In this lab you will experience the real power of Infrastructure as Code: **modifying live infrastructure through code changes**. You will scale the service, adjust container resources, and finally destroy everything with one command.

---

## 📈 Exercise 5.1: Scale the ECS Service

### Step 1 -- Navigate to the Lab 4 Directory

All changes in this lab are made to the same `main.tf` from Lab 4:

```bash
cd ~/environment/fargate-ecs/lab-exercises/lab04
```

### Step 2 -- Edit the Desired Count

Open `main.tf` in the Cloud9 editor (or use `nano`/`vim`) and locate the ECS service resource near the bottom of the file:

```hcl
resource "aws_ecs_service" "nginx_service" {
  ...
  desired_count = 1
  ...
}
```

Change `desired_count` from `1` to `3`:

```hcl
  desired_count = 3
```

Save the file.

### Step 3 -- Preview the Change

```bash
terraform plan
```

Observe the output. You should see:

```
Plan: 0 to add, 1 to change, 0 to destroy.
```

Terraform detected that only the `desired_count` attribute changed and will perform an **in-place update** -- no resources are destroyed or recreated.

### Step 4 -- Apply the Change

```bash
terraform apply
```

Type `yes` when prompted. The update should complete in under a minute.

### Step 5 -- Verify Scaling in the ECS Console

1. Open the **ECS Console**: [https://console.aws.amazon.com/ecs](https://console.aws.amazon.com/ecs)
2. Click into your cluster
3. On the **Services** tab, confirm the service now shows **3/3** running tasks
4. On the **Tasks** tab, confirm all three tasks are in `RUNNING` status

### Step 6 -- Verify Healthy Targets

1. Open the **EC2 Console** > **Target Groups**: [https://console.aws.amazon.com/ec2/home#TargetGroups](https://console.aws.amazon.com/ec2/home#TargetGroups)
2. Click on your target group (e.g., `user3-target-group`)
3. On the **Targets** tab, confirm **3 healthy targets** are registered (may take 1-2 minutes)

### Step 7 -- Test Load Balancing

Run several curl requests and observe the responses:

```bash
ALB_DNS=$(terraform state show aws_lb.alb | grep "dns_name" | head -1 | awk '{print $3}' | tr -d '"')
for i in 1 2 3 4 5; do
  echo "--- Request $i ---"
  curl -s http://$ALB_DNS | head -5
  echo ""
done
```

All requests return the same Nginx welcome page because all three tasks run the same container image. In a real-world scenario with custom applications, you could observe different task IPs responding.

---

## ⚙️ Exercise 5.2: Modify Container Configuration

Now let's change the CPU and memory allocation for the Fargate task.

### Step 1 -- Edit the Task Definition Resource-Level Values

In `main.tf`, locate the task definition resource:

```hcl
resource "aws_ecs_task_definition" "nginx" {
  ...
  cpu                      = "256"
  memory                   = "512"
  ...
}
```

Change these to:

```hcl
  cpu                      = "512"
  memory                   = "1024"
```

### Step 2 -- Edit the Container Definition Values

In the same resource, also update the `cpu` and `memory` values **inside** the `container_definitions` block:

```hcl
  container_definitions = jsonencode([
    {
      name  = "userX-container"
      image = "nginx:latest"
      cpu   = 256       # <-- Change to 512
      memory = 512      # <-- Change to 1024
      ...
    }
  ])
```

Change them to:

```hcl
      cpu   = 512
      memory = 1024
```

Save the file.

> **Important:** Both the task-level and container-level values must be updated. The task-level values define the Fargate resource allocation, and the container-level values define the resource limits for the individual container.

### Step 3 -- Preview the Change

```bash
terraform plan
```

Observe the output carefully. You should see:

- The **task definition** will be **replaced** (forces new resource) -- Terraform creates a new task definition revision
- The **ECS service** will be **updated in-place** to reference the new task definition revision

This is because task definitions in ECS are **immutable** -- you cannot edit an existing revision; a new revision is created instead.

### Step 4 -- Apply the Change

```bash
terraform apply
```

Type `yes` when prompted. Watch as Terraform creates the new task definition revision and updates the service. ECS will perform a **rolling deployment**, draining old tasks and starting new ones.

### Step 5 -- Verify the New Task Definition

1. Open the **ECS Console**: [https://console.aws.amazon.com/ecs](https://console.aws.amazon.com/ecs)
2. Navigate to **Task Definitions** in the left sidebar
3. Click on your task definition family (e.g., `user3-task`)
4. Confirm a **new revision** exists (e.g., revision 2)
5. Click into the new revision and verify the CPU is `512` (0.5 vCPU) and memory is `1024` MiB (1 GB)

---

## 💥 Exercise 5.3: Destroy All Resources

One of the most powerful benefits of Infrastructure as Code is **clean, complete teardown**.

### Step 1 -- Preview the Destruction Plan

```bash
terraform plan -destroy
```

Review the output. Terraform shows every resource it will destroy, in **reverse dependency order**:

1. ECS service (drains tasks first)
2. Listener
3. Target group
4. ALB
5. Task definition
6. Security groups
7. ECS cluster

### Step 2 -- Destroy All Resources

```bash
terraform destroy
```

Type `yes` when prompted. Watch the output as Terraform tears down each resource. This typically takes **2-3 minutes**, with the ECS service taking the longest as it drains running tasks.

### Step 3 -- Confirm Empty State

```bash
terraform state list
```

This should produce **no output**, confirming that Terraform is no longer tracking any resources.

---

### 🎉 Success

An empty state list is your proof: Terraform tracked twelve entries a moment
ago and now tracks none.

**Compare this one-command cleanup to the 8-step manual cleanup in Lab 2.** There
you deleted the ECS service, waited for tasks to drain, deregistered the task
definition, deleted the cluster, the ALB, the target group, and two security
groups -- each one several console clicks, all in the correct dependency order.
Here, a single `terraform destroy` did the lot. **This is the power of
Infrastructure as Code.**

> **Want to double-check in the console?** Open **ECS** > **Clusters** and
> **EC2** > **Load Balancers / Target Groups / Security Groups**. Everything
> prefixed with your username should be gone. The empty state list already tells
> you this, so treat it as optional.

---

## 🎓 Exercise 5.4: Course Wrap-Up

### Console vs. Terraform -- Side-by-Side Comparison

| Dimension | AWS Console (Labs 1-2) | Terraform (Labs 4-5) |
|-----------|----------------------|---------------------|
| **Deploy Time** | 15-20 minutes of clicking | 2-4 minutes (`terraform apply`) |
| **Repeatability** | Difficult -- depends on memory and notes | Exact -- same config produces same result every time |
| **Scaling** | Navigate to service, update, wait | Change one number, `terraform apply` |
| **Cleanup** | 8+ manual steps across multiple consoles | One command: `terraform destroy` |
| **Collaboration** | Screenshots and documentation | Git-versioned `.tf` files with code review |
| **Audit Trail** | CloudTrail logs (after the fact) | Git commit history (before and after) |
| **Disaster Recovery** | Rebuild manually from documentation | `terraform apply` from the same config |
| **Environment Parity** | Error-prone manual duplication | Same config, different variable values |

### Suggested Next Steps

Continue your ECS Fargate and Infrastructure as Code learning with these topics:

- **Amazon ECR (Elastic Container Registry)** -- Build and push custom Docker images instead of using `nginx:latest`
- **CI/CD Pipelines** -- Automate deployments with AWS CodePipeline, GitHub Actions, or GitLab CI
- **ECS Exec** -- Use `aws ecs execute-command` to get a shell inside a running Fargate container for debugging
- **Service Discovery** -- Use AWS Cloud Map for service-to-service communication without load balancers
- **Terraform Remote State** -- Store state in S3 with DynamoDB locking for team collaboration
- **Terraform Modules** -- Package reusable ECS configurations as shareable modules
- **Auto Scaling** -- Configure ECS Service Auto Scaling to adjust task count based on CPU/memory metrics
- **Blue/Green Deployments** -- Use AWS CodeDeploy with ECS for zero-downtime releases

---

## 🔧 Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| `terraform destroy` hangs for several minutes | ECS tasks are draining (graceful shutdown) | This is normal; wait for tasks to finish draining. Check the ECS Console > Tasks tab to see drain progress |
| Security group deletion fails with `DependencyViolation` | ENIs from Fargate tasks are still attached | Wait 2-3 minutes for ENIs to be released, then run `terraform destroy` again |
| `Error: Resource already exists` after a partial destroy | Previous destroy was interrupted | Run `terraform destroy` again; Terraform will pick up where it left off |
| State file shows resources but they were deleted manually | State is out of sync with reality | Run `terraform refresh` to update state, then `terraform destroy` to clean up |
| `terraform plan` shows unexpected changes | File was edited incorrectly | Run `cat main.tf` to review; compare with the instructions above |

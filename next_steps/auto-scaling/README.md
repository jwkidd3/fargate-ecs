# Bonus Lab: ECS Service Auto Scaling

**Duration:** 30 minutes
**Difficulty:** Introductory
**Prerequisite:** Lab 4 completed (resources deployed), or re-deploy Lab 4 first

---

## Overview

In Labs 2 and 5 you scaled manually by changing the `desired_count`. In production, you configure **auto scaling** so ECS adjusts the task count automatically based on metrics like CPU or memory utilization. In this exercise you will add an Application Auto Scaling target-tracking policy that scales your ECS service based on average CPU utilization.

---

## Exercise 1: Add Auto Scaling Resources to Terraform

### Step 1 — Navigate to the Lab 4 Directory

```bash
cd ~/environment/fargate-ecs/lab-exercises/lab04
```

If you previously destroyed your Lab 4/5 resources, redeploy them first:

```bash
terraform init
terraform apply
```

### Step 2 — Add the Auto Scaling Target

Open `main.tf` and add the following at the **bottom** of the file. Replace `userX` with your assigned username:

```hcl
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 6
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.nginx_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}
```

This resource tells Application Auto Scaling to manage the `DesiredCount` of your ECS service, with a minimum of 1 task and a maximum of 6.

### Step 3 — Add the Target-Tracking Scaling Policy

Add this resource immediately after the scaling target:

```hcl
resource "aws_appautoscaling_policy" "ecs_cpu_policy" {
  name               = "userX-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 70.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}
```

### Step 4 — Understand What You Wrote

| Attribute | Value | Purpose |
|-----------|-------|---------|
| `max_capacity` | `6` | Maximum number of tasks Auto Scaling can launch |
| `min_capacity` | `1` | Minimum number of tasks (never scales below this) |
| `target_value` | `70.0` | Target average CPU utilization (percentage) |
| `predefined_metric_type` | `ECSServiceAverageCPUUtilization` | The metric Auto Scaling tracks |
| `scale_in_cooldown` | `60` | Wait 60 seconds after scaling in before allowing another scale-in |
| `scale_out_cooldown` | `60` | Wait 60 seconds after scaling out before allowing another scale-out |

**How it works:** If the average CPU utilization across all tasks exceeds 70%, Auto Scaling adds tasks to bring it back down. If utilization drops well below 70%, it removes tasks (down to `min_capacity`).

---

## Exercise 2: Deploy the Auto Scaling Policy

### Step 1 — Preview the Changes

```bash
terraform plan
```

You should see:

```
Plan: 2 to add, 0 to change, 0 to destroy.
```

The two new resources are the scaling target and the scaling policy.

### Step 2 — Apply

```bash
terraform apply
```

Type **yes** when prompted.

### Step 3 — Verify in the AWS Console

1. Open the **ECS Console**: [https://console.aws.amazon.com/ecs](https://console.aws.amazon.com/ecs)
2. Click into your cluster, then click on your service
3. Click the **Auto Scaling** tab (or **Service auto scaling** depending on the console version)
4. Confirm you see a target-tracking policy with a target of **70% CPU utilization**
5. Verify the min/max capacity shows **1 / 6**

---

## Exercise 3: Generate Load and Observe Scaling

### Step 1 — Get the ALB DNS Name

```bash
ALB_DNS=$(terraform state show aws_lb.alb | grep "dns_name" | head -1 | awk '{print $3}' | tr -d '"')
echo $ALB_DNS
```

### Step 2 — Check Current Task Count

```bash
aws ecs describe-services \
  --cluster userX-cluster \
  --services userX-service \
  --query 'services[0].{desired:desiredCount,running:runningCount}' \
  --output table
```

You should see 1 desired and 1 running.

### Step 3 — Generate Load

Open a **second Cloud9 terminal tab** (Window > New Terminal) and run a sustained load test:

```bash
ALB_DNS=$(terraform state show aws_lb.alb | grep "dns_name" | head -1 | awk '{print $3}' | tr -d '"')
while true; do
  curl -s http://$ALB_DNS > /dev/null &
  curl -s http://$ALB_DNS > /dev/null &
  curl -s http://$ALB_DNS > /dev/null &
  curl -s http://$ALB_DNS > /dev/null &
  curl -s http://$ALB_DNS > /dev/null &
  wait
done
```

> **Note:** This sends 5 concurrent requests in a loop. For a 256 CPU (0.25 vCPU) Fargate task, this generates meaningful CPU load. Nginx itself is lightweight, so scaling may take several minutes to trigger.

### Step 4 — Monitor Scaling

In the **first terminal**, periodically check the task count:

```bash
watch -n 10 "aws ecs describe-services --cluster userX-cluster --services userX-service --query 'services[0].{desired:desiredCount,running:runningCount}' --output table"
```

You can also monitor in the ECS Console:
1. Navigate to your service's **Tasks** tab
2. Watch for new tasks appearing as Auto Scaling responds to increased CPU

> **Note:** Auto Scaling typically takes 3-5 minutes to react. CloudWatch metrics are evaluated on 1-minute intervals, and the cooldown period adds additional delay. Be patient.

### Step 5 — Stop the Load

In the **second terminal**, press `Ctrl+C` to stop the load generator.

After the `scale_in_cooldown` period, Auto Scaling will begin removing tasks as CPU drops below the target. This may take several minutes.

### Step 6 — Observe Scale-In

Continue watching the task count. Eventually, the desired count should return to `1` (the `min_capacity`).

---

## Exercise 4: Clean Up

### Step 1 — Destroy All Resources

```bash
terraform destroy
```

Type **yes** when prompted. Terraform will remove the auto scaling policy, scaling target, and all other resources.

### Step 2 — Verify

```bash
terraform state list
```

This should produce no output.

---

## What You Learned

- How **ECS Service Auto Scaling** works with Application Auto Scaling
- The difference between **manual scaling** (`desired_count`) and **automatic scaling** (target-tracking policies)
- How to define `aws_appautoscaling_target` and `aws_appautoscaling_policy` in Terraform
- That target-tracking scaling uses CloudWatch metrics to maintain a target utilization
- How **cooldown periods** prevent rapid scaling oscillation
- The end-to-end flow: load increases → CPU rises → Auto Scaling adds tasks → CPU drops → Auto Scaling removes tasks

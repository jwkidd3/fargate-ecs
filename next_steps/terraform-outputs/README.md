# 📤 Bonus Lab: Expose Values with Terraform Outputs

**Duration:** 15 minutes
**Difficulty:** Introductory
**Prerequisite:** Lab 4 complete, stack still deployed (do this *before* Lab 5's destroy)

---

## Overview

So far you have read values out of your infrastructure by hand -- scrolling
`terraform apply` output for the ALB DNS name, or clicking into the EC2 Console.
**Outputs** declare those values as part of your configuration, so Terraform
prints them on every apply and can hand them to scripts and pipelines.

They are useful for scripting, CI/CD pipelines, and cross-stack references.

## Step 1 — Add Output Blocks

Open `main.tf` and add the following at the **bottom** of the file:

```hcl
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.alb.dns_name
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.nginx_service.name
}
```

Save the file.

## Step 2 — Apply the Outputs

```bash
terraform apply
```

Type `yes` when prompted. Notice the plan summary:

```
No changes. Your infrastructure matches the configuration.
```

Outputs do not cause any infrastructure changes -- they simply extract and display values from the state.

After the apply completes, the output values are printed at the bottom:

```
Outputs:

alb_dns_name = "userX-alb-1234567890.us-east-1.elb.amazonaws.com"
cluster_name = "userX-cluster"
service_name = "userX-service"
```

## Step 3 — Query Outputs

List all outputs:

```bash
terraform output
```

Query a single output (useful in scripts):

```bash
terraform output alb_dns_name
```

Query a single output with no quotes (raw mode, ideal for piping):

```bash
terraform output -raw alb_dns_name
```

> **Tip:** In production, outputs are frequently used to pass values between Terraform modules or to CI/CD pipelines. For example: `curl http://$(terraform output -raw alb_dns_name)`

---

## What You Learned

- `output` blocks expose values from state without changing any infrastructure
- `terraform output <name>` reads a single value; `-raw` strips the quotes for piping
- Outputs are how Terraform modules and CI/CD pipelines pass values to each other

## Next Steps

Return to [Lab 5](../../lab-exercises/lab05/README.md) and continue with the
destroy exercise, or try another bonus lab in [`next_steps/`](../).

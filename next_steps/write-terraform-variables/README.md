# Bonus Lab: Write Terraform From Scratch — Variables

**Duration:** 30 minutes
**Difficulty:** Introductory
**Prerequisite:** Lab 4 completed and still deployed (or redeploy it first)

---

## Overview

In Labs 4 and 5 you customised a pre-built `main.tf` with `sed`:

```bash
sed -i 's/user0/user5/g' main.tf
```

That works, but it is find-and-replace on source code — not configuration. If you
needed a second environment, you would copy the whole file and run `sed` again.

In this exercise you will **author Terraform by hand** to fix that: declare an input
variable, replace every hardcoded name with an interpolated reference, and supply
the value from outside the configuration. This is the single most common refactor in
real Terraform work.

The payoff comes at the end: if you do it correctly, `terraform plan` reports **"No
changes"** — because the names your configuration produces are identical to what is
already deployed. Terraform compares resulting state, not source text.

---

## Exercise 1: Declare the Variable

### Step 1 — Navigate to the Lab 4 Directory

```bash
cd ~/environment/fargate-ecs/lab-exercises/lab04
```

If you destroyed your Lab 4/5 resources, redeploy them first:

```bash
terraform init && terraform apply
```

### Step 2 — Create a Variables File

Terraform loads every `.tf` file in the directory, so variables conventionally live
in their own file. Create `variables.tf`:

```bash
touch variables.tf
```

Open it in the Cloud9 editor and write the following **from scratch** — do not copy
it from elsewhere in the repo:

```hcl
variable "username" {
  description = "Your assigned student username, used to prefix every resource name"
  type        = string

  validation {
    condition     = can(regex("^user[0-9]+$", var.username))
    error_message = "The username must look like user1, user2, user42 — lowercase 'user' followed by digits."
  }
}
```

### Step 3 — Understand What You Wrote

| Block / argument | Purpose |
|------------------|---------|
| `variable "username"` | Declares an input. `username` is how you refer to it: `var.username` |
| `description` | Shown by `terraform plan` and in generated docs. Always write one |
| `type = string` | Terraform rejects a non-string value before contacting AWS |
| `validation` | An optional rule checked at plan time |
| `can(regex(...))` | `regex()` fails hard on no match; `can()` turns that failure into `false` |
| `error_message` | What the user sees when validation fails. Must end with a full stop |

> **Note:** There is no `default`. Omitting it makes the variable **required** —
> Terraform will refuse to plan without a value. That is what you want here: there is
> no sensible default username.

---

## Exercise 2: Use the Variable

### Step 1 — Replace the Hardcoded Names

Open `main.tf`. Every resource name currently contains your username as literal text
(for example `user5-cluster`). Replace each one with an interpolated reference.

Terraform interpolation is `${...}` **inside** a string:

```hcl
# Before
name = "user5-cluster"

# After
name = "${var.username}-cluster"
```

Work through all eight names:

| # | Resource | Before | After |
|---|----------|--------|-------|
| 1 | `aws_ecs_cluster.main` | `"user5-cluster"` | `"${var.username}-cluster"` |
| 2 | `aws_security_group.alb_sg` | `"user5_ALB"` | `"${var.username}_ALB"` |
| 3 | `aws_security_group.ecs_sg` | `"user5_ECS"` | `"${var.username}_ECS"` |
| 4 | `aws_lb.alb` | `"user5-alb"` | `"${var.username}-alb"` |
| 5 | `aws_lb_target_group.tg` | `"user5-target-group"` | `"${var.username}-target-group"` |
| 6 | `aws_cloudwatch_log_group.ecs_logs` | `"/ecs/user5-task"` | `"/ecs/${var.username}-task"` |
| 7 | `aws_ecs_task_definition.nginx` (family) | `"user5-task"` | `"${var.username}-task"` |
| 8 | `aws_ecs_service.nginx_service` | `"user5-service"` | `"${var.username}-service"` |

### Step 2 — Do Not Miss the Container Name

The container name appears **inside** `container_definitions`, and again in the
service's `load_balancer` block. **Both must match**, or ECS cannot work out which
container to register with the target group.

In the task definition:

```hcl
container_definitions = jsonencode([
  {
    name  = "${var.username}-container"
    image = "nginx:latest"
    ...
```

In the service:

```hcl
load_balancer {
  target_group_arn = aws_lb_target_group.tg.arn
  container_name   = "${var.username}-container"
  container_port   = 80
}
```

### Step 3 — Confirm Nothing Was Missed

```bash
grep -n "user[0-9]" main.tf
```

This should return **nothing**. Any line it prints is a name you still need to
convert.

---

## Exercise 3: Supply the Value

A required variable with no value makes Terraform stop and ask. There are three
ways to provide one.

### Step 1 — Try It Without a Value

```bash
terraform plan
```

Terraform prompts interactively:

```
var.username
  Your assigned student username, used to prefix every resource name

  Enter a value:
```

Press `Ctrl+C` to cancel. Prompting is fine for a human at a keyboard, but useless
in a pipeline.

### Step 2 — Test Your Validation Rule

```bash
terraform plan -var="username=Bob"
```

Terraform rejects it before making a single AWS call:

```
Error: Invalid value for variable
...
The username must look like user1, user2, user42 — lowercase 'user' followed by digits.
```

This is your `validation` block working. Catching a bad value here costs a second;
catching it after a half-built deployment costs much more.

### Step 3 — Create a tfvars File

The usual approach. Terraform loads `terraform.tfvars` automatically:

```bash
echo 'username = "userX"' > terraform.tfvars
```

Replace `userX` with your assigned username. Then:

```bash
cat terraform.tfvars
```

> **In the real world** `terraform.tfvars` is usually in `.gitignore` — it holds
> per-environment values, while the `.tf` files hold logic that is identical across
> environments. That separation is the whole point of variables.

### Step 4 — The Payoff

```bash
terraform plan
```

You should see:

```
No changes. Your infrastructure matches the configuration.
```

**Nothing is being rebuilt.** You restructured how the configuration is written, and
because the resulting names are byte-for-byte identical to what is deployed,
Terraform sees no work to do.

If you instead see resources being created or destroyed, a name does not match.
Read the plan — it names the exact attribute — fix it, and plan again.

### Step 5 — Prove It Is Really a Variable

Ask for a plan as if you were a different student:

```bash
terraform plan -var="username=user99"
```

Now Terraform wants to replace everything, because every name changed. **Do not
apply this.** An explicit `-var` on the command line beats `terraform.tfvars`, which
is exactly how a pipeline targets different environments from one configuration.

---

## Exercise 4: Clean Up

If you are finished with the bonus labs:

```bash
terraform destroy
```

Type `yes` when prompted. Your `terraform.tfvars` supplies the username
automatically.

---

## What You Learned

- `variable` blocks declare typed inputs, referenced as `var.<name>`
- A variable with no `default` is **required**
- `validation` with `can(regex(...))` catches bad input at plan time, before any AWS call
- `"${var.name}-suffix"` interpolates a variable into a string
- Values come from `terraform.tfvars`, `-var` on the command line, or `TF_VAR_username`
  in the environment — in increasing order of precedence
- **"No changes" after a refactor means you did it right.** Terraform compares the
  state your configuration produces, not the text you wrote

## Why This Matters

The `sed` workflow from Lab 4 edits source code to change behaviour. This version
separates the two: `main.tf` describes *what the infrastructure is*, and
`terraform.tfvars` says *which instance of it this is*. That is how one configuration
serves dev, staging, and production without a single copy-paste.

## Next Steps

Try another bonus lab in [`next_steps/`](../), or extend this one: add a `variable`
for `desired_count` and `container_image` so the task size and image are configurable
too.

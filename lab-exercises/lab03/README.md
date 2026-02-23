# 🛠️ Lab 3: Install Terraform on Amazon Linux

**Duration:** 45 minutes
**Difficulty:** Introductory
**Day:** 1
**Environment:** AWS Cloud9

---

## 📋 Lab Objectives

By the end of this lab, you will have:

- Opened your Cloud9 environment for the Terraform labs (or created a new one if needed)
- Installed Terraform on your Cloud9 Amazon Linux instance using HashiCorp's official repository
- Explored essential Terraform commands and their purposes
- Verified that Terraform can authenticate with AWS
- Created an ECS cluster with Terraform and verified it in the AWS Console
- Experienced the full Terraform lifecycle: `init`, `plan`, `apply`, `destroy`

---

## 🖥️ Exercise 3.1: Open Your Cloud9 Environment

You will continue using the Cloud9 environment you created in Lab 1. If your environment is still running, open it and skip to Exercise 3.2.

### Step 1 — Open Your Existing Environment

1. Sign in to the **AWS Management Console**
2. In the top navigation bar, confirm the region is **US East (N. Virginia) us-east-1**
3. In the search bar, type **Cloud9** and select it from the results
4. Find your environment (named with your assigned username) and click **Open**

> **If your Cloud9 environment is no longer available** (deleted or expired), follow the steps below to create a new one. Otherwise, skip to Exercise 3.2.

### Creating a New Cloud9 Environment (only if needed)

1. Click **Create environment**
2. Set the **Name** to your assigned username (e.g., `user1`, `user2`, `user3`)
3. Configure the EC2 instance:

| Setting | Value |
|---------|-------|
| **Environment type** | New EC2 instance |
| **Instance type** | m5.large (8 GiB RAM + 2 vCPU) |
| **Platform** | Amazon Linux |
| **Timeout** | 30 minutes |
| **Connection** | **Secure Shell (SSH)** |

> **IMPORTANT:** You must select **Secure Shell (SSH)** as the connection type. Do **not** use AWS Systems Manager (SSM). Selecting SSM will cause networking issues in later exercises.

4. Leave **VPC** and **Subnet** at their default values
5. Click **Create**
6. Wait for the environment to provision (this may take 1-2 minutes)
7. Click the **Open** link next to your environment name to launch the Cloud9 IDE

If you created a new environment, clone the course repository:

```bash
cd ~/environment
git clone https://github.com/jwkidd3/fargate-ecs.git
```

### Step 2 — Verify Environment

Run the following commands in the **Cloud9 terminal**:

```bash
# Verify Amazon Linux
cat /etc/os-release

# Verify the course repo is present
ls ~/environment/fargate-ecs/lab-exercises/
```

You should see directories for all five labs.

---

## 🔧 Exercise 3.2: Install Terraform

### Step 1 — Open Your Cloud9 Terminal

In your Cloud9 workspace, ensure you have a terminal panel open. If not, go to **Window > New Terminal**.

### Step 2 — Install Terraform Using HashiCorp's Official Repository

Run the following commands to add the HashiCorp repository and install Terraform:

```bash
sudo yum install -y yum-utils
```

```bash
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
```

```bash
sudo yum -y install terraform
```

### Step 3 — Verify the Installation

Confirm Terraform is installed and accessible:

```bash
terraform version
```

You should see output similar to:

```
Terraform v1.x.x
on linux_amd64
```

### Step 4 — Enable Tab Completion

Enable Terraform command auto-completion for a smoother workflow:

```bash
terraform -install-autocomplete
```

Reload your shell profile to activate it immediately:

```bash
source ~/.bashrc
```

You can now press **Tab** while typing Terraform commands to auto-complete them.

---

## 📖 Exercise 3.3: Understand Terraform Commands

### Step 1 — Explore the Help Output

Run the following to see all available Terraform commands:

```bash
terraform --help
```

Take a moment to read through the listed commands and their short descriptions.

### Step 2 — Review Essential Commands

The table below summarizes the commands you will use most frequently throughout this course:

| Command | Purpose | When to Use |
|---|---|---|
| `terraform init` | Initialize working directory | First time, or after adding providers |
| `terraform plan` | Preview changes | Before every apply |
| `terraform apply` | Create/update infrastructure | When ready to deploy |
| `terraform destroy` | Remove all infrastructure | When done with resources |
| `terraform state list` | List tracked resources | To see what Terraform manages |
| `terraform state show` | Show resource details | To inspect a specific resource |

> **Tip:** You can also run `terraform <command> --help` to get detailed help for any specific command. For example: `terraform plan --help`.

---

## 🔑 Exercise 3.4: Verify AWS Provider Configuration

Cloud9 automatically provides temporary AWS credentials through its managed credentials feature. In this exercise, you will confirm that Terraform can use those credentials.

### Step 1 — Verify AWS Credentials

Run the following command to confirm your identity and that valid credentials are available:

```bash
aws sts get-caller-identity
```

You should see JSON output containing your `UserId`, `Account`, and `Arn`. This confirms that AWS CLI (and by extension, Terraform) can authenticate with AWS.

### Step 2 — Verify Your AWS Region

Check the currently configured region:

```bash
aws configure get region
```

If the command returns blank or a region other than `us-east-1`, set it explicitly:

```bash
aws configure set region us-east-1
```

Confirm the region is now set:

```bash
aws configure get region
```

You should see:

```
us-east-1
```

---

## 🚀 Exercise 3.5: Create an ECS Cluster with Terraform

Now you will create a real AWS resource — an ECS cluster — using Terraform. This exercise walks through the complete `init` → `plan` → `apply` → `destroy` lifecycle and previews the ECS resources you will deploy in Labs 4 and 5.

### Step 1 — Create a Test Directory

```bash
mkdir ~/environment/terraform-test && cd ~/environment/terraform-test
```

### Step 2 — Create the Terraform Configuration

Create a file called `main.tf` and type the following content exactly. Replace `userX` with your assigned username (e.g., `user1`, `user2`, `user3`):

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_ecs_cluster" "test" {
  name = "userX-test-cluster"
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.test.name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.test.arn
}
```

This configuration does the following:

- Declares the AWS provider from the HashiCorp registry (version 5.x)
- Configures the provider to use the `us-east-1` region
- Creates an **ECS cluster** — the same resource type you created manually in Lab 1
- Outputs the cluster name and ARN

### Step 3 — Initialize the Configuration

```bash
terraform init
```

Terraform will download the AWS provider plugin. You should see a message ending with:

```
Terraform has been successfully initialized!
```

Take a moment to explore what was created:

```bash
ls -la .terraform/
```

```bash
ls -la .terraform/providers/
```

The `.terraform/` directory stores the downloaded provider plugins and other metadata that Terraform needs.

### Step 4 — Preview the Changes

```bash
terraform plan
```

Terraform will show you what it intends to do. You should see:

```
Plan: 1 to add, 0 to change, 0 to destroy.
```

Notice how Terraform tells you **exactly** what it will create before it does anything. Compare this to the console, where you click "Create" and hope for the best.

### Step 5 — Apply the Configuration

```bash
terraform apply
```

When prompted, type **yes** and press Enter.

Terraform will create the ECS cluster and display the outputs:

```
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

cluster_arn = "arn:aws:ecs:us-east-1:123456789012:cluster/userX-test-cluster"
cluster_name = "userX-test-cluster"
```

### Step 6 — Verify in the AWS Console

1. Open the **ECS Console**: [https://console.aws.amazon.com/ecs](https://console.aws.amazon.com/ecs)
2. Click **Clusters** in the left navigation
3. Confirm that `userX-test-cluster` appears in the cluster list with **ACTIVE** status

You just created the same type of resource from Lab 1 — but with a single command instead of clicking through the console.

### Step 7 — Explore the Terraform State

List the resources Terraform is tracking:

```bash
terraform state list
```

You should see:

```
aws_ecs_cluster.test
```

Inspect the cluster details:

```bash
terraform state show aws_ecs_cluster.test
```

This shows every attribute of the cluster that Terraform recorded, including the ARN, name, and status.

### Step 8 — Destroy the Cluster

```bash
terraform destroy
```

When prompted, type **yes** and press Enter. Terraform will remove the ECS cluster.

```
Destroy complete! Resources: 1 destroyed.
```

### Step 9 — Verify Cleanup

1. Return to the **ECS Console** and refresh the Clusters page
2. Confirm that `userX-test-cluster` is **no longer listed**

One command created the cluster. One command destroyed it. In Lab 4, you will use this same workflow to deploy an entire ECS Fargate stack — cluster, security groups, ALB, task definition, and service — all at once.

### Step 10 — Remove the Test Directory

```bash
cd ~/environment && rm -rf terraform-test
```

---

## ✅ Lab Summary

Use the checklist below to confirm you have completed all objectives:

- [ ] Cloud9 environment is running (m5.large, Amazon Linux, SSH, us-east-1)
- [ ] Course repository is cloned to `~/environment/fargate-ecs`
- [ ] Terraform is installed and `terraform version` returns a valid version
- [ ] You understand the essential Terraform commands (`init`, `plan`, `apply`, `destroy`, `state list`, `state show`)
- [ ] AWS credentials are working and `aws sts get-caller-identity` returns your account details
- [ ] You created an ECS cluster with `terraform apply` and verified it in the console
- [ ] You destroyed the ECS cluster with `terraform destroy` and confirmed it was removed
- [ ] The test directory has been cleaned up

**Connection to next lab:** You just used Terraform to create and destroy a single ECS cluster. In Lab 4, you will use the same workflow to deploy an **entire ECS Fargate stack** — cluster, security groups, ALB, task definition, and service — from a single `main.tf` file.

---

## 🔍 Troubleshooting

### Cloud9 IDE does not open

Verify you are in the **us-east-1** region. Check that pop-ups are not blocked in your browser. Try refreshing the page. If the issue persists, delete the environment and recreate it.

### "Unable to access your environment"

Wait 1-2 minutes and try again. Cloud9 environments can take time to fully provision. If the error continues, delete and recreate the environment.

### "terraform: command not found"

- Verify the installation completed without errors by re-running `sudo yum -y install terraform`
- Check that Terraform is on your PATH:
  ```bash
  which terraform
  ```
- If the binary exists but is not found, add its location to your PATH:
  ```bash
  export PATH=$PATH:/usr/bin
  ```

### AWS Credentials Error

Cloud9 manages AWS credentials automatically through its built-in managed credentials feature. If you encounter credential errors:

1. In Cloud9, go to **Settings** (gear icon) > **AWS Settings**
2. Confirm that **AWS managed temporary credentials** is turned **on**
3. Restart your terminal and try again

### "No valid credential sources found"

1. Run `aws sts get-caller-identity` to test whether the AWS CLI can authenticate
2. If it fails, open Cloud9 **Preferences** > **AWS Settings** > **Credentials** and verify managed credentials are enabled
3. If the issue persists, try closing and reopening the Cloud9 terminal

### Terraform Init Fails to Download Provider

- Verify internet connectivity: `curl -s https://registry.terraform.io` should return a response
- Check that the HashiCorp repository was added correctly: `yum repolist | grep hashicorp`
- Ensure your `main.tf` file has no syntax errors: `terraform validate`

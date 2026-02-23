# Bonus Lab: Build and Deploy a Custom Container Image with ECR

**Duration:** 45 minutes
**Difficulty:** Introductory
**Prerequisite:** Lab 4 completed (resources deployed), or re-deploy Lab 4 first

---

## Overview

Throughout the course you deployed `nginx:latest` — a public image from Docker Hub. In production, you deploy **your own images** stored in a private registry. In this exercise you will create an Amazon ECR repository, build a custom Docker image with a personalized welcome page, push it to ECR, and update the Terraform configuration to use your custom image.

---

## Exercise 1: Create an ECR Repository

### Step 1 — Create the Repository

Run the following command in your Cloud9 terminal. Replace `userX` with your assigned username:

```bash
aws ecr create-repository --repository-name userX-nginx --region us-east-1
```

You should see JSON output containing the `repositoryUri`. Copy this value — it looks like:

```
123456789012.dkr.ecr.us-east-1.amazonaws.com/userX-nginx
```

### Step 2 — Store the Repository URI

Save the URI in a variable for later use:

```bash
ECR_URI=$(aws ecr describe-repositories --repository-names userX-nginx --query 'repositories[0].repositoryUri' --output text)
echo $ECR_URI
```

### Step 3 — Authenticate Docker with ECR

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URI
```

You should see `Login Succeeded`.

---

## Exercise 2: Build a Custom Docker Image

### Step 1 — Create a Working Directory

```bash
mkdir ~/environment/custom-nginx && cd ~/environment/custom-nginx
```

### Step 2 — Create a Custom Welcome Page

Create a file called `index.html`:

```bash
cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>ECS Fargate - Custom Deployment</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #232F3E 0%, #FF9900 100%);
            color: white;
        }
        .container {
            text-align: center;
            padding: 40px;
            background: rgba(0,0,0,0.3);
            border-radius: 15px;
        }
        h1 { font-size: 2.5em; margin-bottom: 10px; }
        p { font-size: 1.2em; opacity: 0.9; }
        .highlight { color: #FF9900; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Hello from ECS Fargate!</h1>
        <p>Deployed by <span class="highlight">userX</span></p>
        <p>Custom image from Amazon ECR</p>
        <p>Running on AWS Fargate</p>
    </div>
</body>
</html>
EOF
```

> **Note:** Replace `userX` in the HTML with your assigned username.

### Step 3 — Create a Dockerfile

```bash
cat > Dockerfile << 'EOF'
FROM nginx:latest
COPY index.html /usr/share/nginx/html/index.html
EOF
```

This Dockerfile starts from the official nginx image and replaces the default welcome page with your custom one.

### Step 4 — Build the Image

```bash
docker build -t userX-nginx .
```

### Step 5 — Test Locally (Optional)

```bash
docker run -d -p 8080:80 --name test-nginx userX-nginx
curl http://localhost:8080
docker stop test-nginx && docker rm test-nginx
```

You should see your custom HTML in the `curl` output.

---

## Exercise 3: Push to ECR

### Step 1 — Tag the Image

```bash
docker tag userX-nginx:latest $ECR_URI:latest
```

### Step 2 — Push to ECR

```bash
docker push $ECR_URI:latest
```

Wait for the push to complete. You should see layer upload progress followed by the digest.

### Step 3 — Verify in the Console

1. Open the **ECR Console**: [https://console.aws.amazon.com/ecr](https://console.aws.amazon.com/ecr)
2. Click on your repository (`userX-nginx`)
3. Confirm the `latest` tag appears with the image you just pushed

---

## Exercise 4: Update the Terraform Configuration

### Step 1 — Navigate to Lab 4

```bash
cd ~/environment/fargate-ecs/lab-exercises/lab04
```

### Step 2 — Update the Image in main.tf

Open `main.tf` and locate the `container_definitions` block. Find the line:

```hcl
      image = "nginx:latest"
```

Replace it with your ECR image URI:

```hcl
      image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/userX-nginx:latest"
```

> **Tip:** Run `echo $ECR_URI` to get your exact URI. The format is `<account-id>.dkr.ecr.us-east-1.amazonaws.com/userX-nginx:latest`.

### Step 3 — Preview and Apply

```bash
terraform plan
```

You should see the task definition will be **replaced** (new revision) and the service will be **updated** to use the new revision.

```bash
terraform apply
```

Type **yes** when prompted. ECS will perform a rolling deployment, replacing tasks running the old image with tasks running your custom image.

### Step 4 — Verify the Custom Page

Wait 1-2 minutes for the rolling deployment and health checks, then:

```bash
ALB_DNS=$(terraform state show aws_lb.alb | grep "dns_name" | head -1 | awk '{print $3}' | tr -d '"')
curl http://$ALB_DNS
```

You should see your custom HTML with "Hello from ECS Fargate!" instead of the default nginx welcome page.

Open the ALB DNS in a browser to see the styled page.

---

## Exercise 5: Clean Up

### Step 1 — Destroy Terraform Resources (if finished with all bonus labs)

```bash
terraform destroy
```

### Step 2 — Delete the ECR Repository

The ECR repository is not managed by Terraform (you created it with the AWS CLI), so delete it separately:

```bash
aws ecr delete-repository --repository-name userX-nginx --region us-east-1 --force
```

The `--force` flag deletes the repository even if it contains images.

### Step 3 — Remove the Build Directory

```bash
cd ~/environment && rm -rf custom-nginx
```

---

## What You Learned

- How to create an **Amazon ECR** private repository
- How to build a **custom Docker image** and push it to ECR
- How to authenticate Docker with ECR using `aws ecr get-login-password`
- How to update a Terraform task definition to reference a **private ECR image** instead of a public Docker Hub image
- That ECS Fargate performs a **rolling deployment** when the task definition image changes
- The difference between public images (Docker Hub) and private images (ECR) in production workflows

# AWS ECS Fargate: Container Orchestration on AWS

**A one-day intensive training course on deploying and managing containers with Amazon ECS Fargate**

[![ECS](https://img.shields.io/badge/Amazon%20ECS-Fargate-FF9900)](https://aws.amazon.com/ecs/)
[![AWS](https://img.shields.io/badge/AWS-Cloud9-FF9900)](https://aws.amazon.com/cloud9/)
[![Duration](https://img.shields.io/badge/Duration-1%20Day-blue)](#)

## Course Overview

**Duration**: 1 day (7 hours hands-on labs + theory)
**Format**: 70% Hands-on / 30% Theory
**Level**: Introductory
**Environment**: AWS Cloud9 on Amazon Linux

## Course Structure

### Morning: ECS Fundamentals and Console Deployment (3.5 hours)

- **Module 1**: Introduction to Amazon ECS (45 min theory)
- **Lab 1**: Deploy Nginx on ECS Fargate via AWS Console (60 min)
- **Module 2**: ECS Architecture and Networking (30 min theory)
- **Lab 2**: Scaling, Logging, and Cleanup (30 min)

### Afternoon: Infrastructure as Code with Terraform (3.5 hours)

- **Module 3**: Infrastructure as Code for ECS (30 min theory)
- **Lab 3**: Install Terraform on Amazon Linux (45 min)
- **Module 4**: Deploying and Managing ECS with Terraform (20 min theory)
- **Lab 4**: Deploy ECS Fargate with Terraform (45 min)
- **Lab 5**: Modify, Scale, and Destroy with Terraform (45 min)

## Course Materials

```
fargate-ecs/
├── README.md                              # Course introduction
├── presentations/
│   └── ecs_fargate.html                   # Theory presentation (Reveal.js)
├── lab-exercises/
│   ├── lab01/README.md                    # Lab 1: Deploy Nginx via Console
│   ├── lab02/README.md                    # Lab 2: Scaling, Logging & Cleanup
│   ├── lab03/README.md                    # Lab 3: Install Terraform
│   ├── lab04/
│   │   ├── README.md                      # Lab 4: Deploy ECS with Terraform
│   │   └── main.tf                        # Terraform config for student use
│   └── lab05/README.md                    # Lab 5: Modify, Scale & Destroy
├── next_steps/
│   ├── write-terraform-resource/README.md # Bonus: Add CloudWatch log group in Terraform
│   ├── ecr-custom-image/README.md         # Bonus: Build & deploy custom image via ECR
│   └── auto-scaling/README.md             # Bonus: ECS Service Auto Scaling policy
└── archive/                               # Pre-course reference material
    ├── main.tf                            # Reference Terraform config
    ├── WebConsole.md                      # Console deployment notes
    ├── intro-ecs.pdf                      # ECS introduction PDF
    └── ecs-dg.pdf                         # ECS developer guide PDF
```

## Getting Started

### For Instructors
1. Open the presentation in [`presentations/ecs_fargate.html`](presentations/ecs_fargate.html) in any browser
2. Review labs in [`lab-exercises/`](lab-exercises/)
3. Ensure the `ecsTaskExecutionRole` IAM role exists in the training AWS account

### For Students
1. Begin with [Lab 1 - Deploy Nginx via Console](lab-exercises/lab01/README.md)
2. Complete labs 1-5 in order
3. Each lab builds on the previous one

### Prerequisites
- **AWS Cloud9** environment (created in Lab 1)
- Assigned username (user1, user2, user3, etc.)
- AWS account with ECS, IAM, and VPC permissions

## Learning Outcomes

### ECS Core Skills
- Explain the ECS architecture: clusters, task definitions, tasks, and services
- Compare Fargate and EC2 launch types
- Deploy containerized applications using the AWS Console
- Configure Application Load Balancers for ECS services
- Scale ECS services and monitor with CloudWatch

### Infrastructure as Code Skills
- Install and configure Terraform on Amazon Linux
- Read and understand an ECS Terraform configuration
- Deploy a complete ECS Fargate stack with Terraform
- Modify, scale, and destroy infrastructure with code
- Compare manual vs IaC deployment workflows

## Bonus Labs (Next Steps)

Three self-paced bonus exercises in [`next_steps/`](next_steps/) for students who finish early or want to continue learning:

| Bonus Lab | Duration | What You'll Do |
|-----------|----------|----------------|
| [Write a Terraform Resource](next_steps/write-terraform-resource/README.md) | 30 min | Add a CloudWatch log group resource and wire container logging — write Terraform from scratch |
| [Build & Deploy a Custom Image](next_steps/ecr-custom-image/README.md) | 45 min | Create an ECR repository, build a custom Docker image, push to ECR, deploy via Terraform |
| [ECS Service Auto Scaling](next_steps/auto-scaling/README.md) | 30 min | Add a target-tracking auto scaling policy that scales tasks based on CPU utilization |

## Course Metrics

- **225 minutes** of hands-on lab time (5 core labs)
- **125 minutes** of theory and presentation
- **105 minutes** of bonus lab content (3 next-steps labs)
- **2 deployment methods**: AWS Console and Terraform
- **Same architecture, two approaches**: build it manually, then automate it

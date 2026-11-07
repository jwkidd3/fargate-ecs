# AWS ECS Fargate: Container Orchestration on AWS

**A one-day intensive training course on deploying and managing containers with Amazon ECS Fargate**

[![ECS](https://img.shields.io/badge/Amazon%20ECS-Fargate-FF9900)](https://aws.amazon.com/ecs/)
[![AWS](https://img.shields.io/badge/AWS-Cloud9-FF9900)](https://aws.amazon.com/cloud9/)
[![Duration](https://img.shields.io/badge/Duration-1%20Day-blue)](#)

## Course Overview

**Schedule**: One day, 9:00 AM - 4:00 PM (60-minute lunch, two 15-minute breaks)
**Instruction time**: 5 hours 19 minutes (319 minutes), leaving 11 minutes of float
**Format**: 65% Hands-on (208 min) / 35% Theory (111 min)
**Level**: Introductory
**Environment**: Labs 1-2 are console-only; Labs 3-5 use AWS Cloud9 on Amazon Linux 2

## Course Structure

### Morning: ECS Fundamentals and Console Deployment (2h 30m instruction)

| Time | Block |
|------|-------|
| 9:00 | Welcome, agenda, objectives (7 min) |
| 9:07 | **Module 1**: Introduction to Amazon ECS (33 min theory) |
| 9:40 | *Break* (15 min) |
| 9:55 | **Lab 1**: Deploy Nginx on ECS Fargate via AWS Console (50 min) |
| 10:45 | **Module 2**: ECS Architecture and Networking (25 min theory) |
| 11:10 | **Lab 2**: Scaling, Logging, and Cleanup (30 min) |
| 11:40 | Morning recap (5 min) |
| 11:45 | *Lunch* (60 min) |

### Afternoon: Infrastructure as Code with Terraform (2h 49m instruction)

| Time | Block |
|------|-------|
| 12:45 | **Module 3**: Infrastructure as Code for ECS (18 min theory) |
| 1:03 | **Lab 3**: Build Your Cloud9 Workstation (46 min) |
| 1:49 | *Break* (15 min) |
| 2:04 | **Module 4**: Deploying and Managing ECS with Terraform (16 min theory) |
| 2:20 | **Lab 4**: Deploy ECS Fargate with Terraform (40 min) |
| 3:00 | **Lab 5**: Modify, Scale, and Destroy with Terraform (42 min) |
| 3:42 | Course recap and next steps (7 min) |
| 3:49 | **Ends** - 11 minutes of float before 4:00 |

> **Lunch is the float.** The morning carries no spare time of its own, so if it
> runs long, lunch starts late rather than the afternoon starting short.

### Where Cloud9 Fits

Labs 1 and 2 are **entirely console-based** and need no terminal. Students build
their Cloud9 workstation at the start of **Lab 3**, where Terraform first needs a
shell, by running [`scripts/bootstrap.sh`](scripts/bootstrap.sh) - one command
that grows the root disk to 100 GB and installs Terraform, AWS CLI v2, Docker,
`jq`, `tree` and `git`.

## Course Materials

```
fargate-ecs/
├── README.md                              # Course introduction
├── COURSE-VALIDATION.md                   # Timing validation and delivery notes
├── scripts/
│   └── bootstrap.sh                       # Cloud9 setup: 100 GB disk + all tools
├── presentations/
│   └── ecs_fargate.html                   # Theory presentation (Reveal.js, 42 slides)
├── lab-exercises/
│   ├── lab01/README.md                    # Lab 1: Deploy Nginx via Console
│   ├── lab02/README.md                    # Lab 2: Scaling, Logging & Cleanup
│   ├── lab03/README.md                    # Lab 3: Build Your Cloud9 Workstation
│   ├── lab04/
│   │   ├── README.md                      # Lab 4: Deploy ECS with Terraform
│   │   └── main.tf                        # Terraform config for student use
│   └── lab05/README.md                    # Lab 5: Modify, Scale & Destroy
├── next_steps/
│   ├── terraform-outputs/README.md        # Bonus: Expose values with Terraform outputs
│   ├── write-terraform-variables/README.md # Bonus: Replace sed with a Terraform variable
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
1. **Verify Cloud9 works in the training account before the day.** AWS closed
   Cloud9 to new customers in August 2024. Accounts that used it before then keep
   access; new accounts cannot create environments, which would block Labs 3-5.
   See [`COURSE-VALIDATION.md`](COURSE-VALIDATION.md) for the fallback plan.
2. Ensure the `ecsTaskExecutionRole` IAM role exists in the training AWS account
3. Confirm student environments can call `ec2:ModifyVolume`, or the disk resize in
   `bootstrap.sh` will warn and skip (Labs 3-5 still work on the 10 GB default)
4. Smoke-test [`scripts/bootstrap.sh`](scripts/bootstrap.sh) on one Cloud9 environment
5. Open the presentation in [`presentations/ecs_fargate.html`](presentations/ecs_fargate.html) in any browser
6. Review labs in [`lab-exercises/`](lab-exercises/) and read the delivery notes in
   [`COURSE-VALIDATION.md`](COURSE-VALIDATION.md)

### For Students
1. Begin with [Lab 1 - Deploy Nginx via Console](lab-exercises/lab01/README.md)
2. Complete labs 1-5 in order
3. Each lab builds on the previous one

### Prerequisites
- Assigned username (user1, user2, user3, etc.)
- AWS account with ECS, IAM, VPC, and EC2 permissions
- **AWS Cloud9** environment - you create this in Lab 3, not before

## Learning Outcomes

### ECS Core Skills
- Explain the ECS architecture: clusters, task definitions, tasks, and services
- Compare Fargate and EC2 launch types
- Deploy containerized applications using the AWS Console
- Configure Application Load Balancers for ECS services
- Scale ECS services and monitor with CloudWatch

### Infrastructure as Code Skills
- Build a working Cloud9 workstation with a single bootstrap script
- Read and understand an ECS Terraform configuration
- Deploy a complete ECS Fargate stack with Terraform
- Modify, scale, and destroy infrastructure with code
- Compare manual vs IaC deployment workflows

## Bonus Labs (Next Steps)

Four self-paced bonus exercises in [`next_steps/`](next_steps/) for students who finish early or want to continue learning:

| Bonus Lab | Duration | What You'll Do |
|-----------|----------|----------------|
| [Terraform Outputs](next_steps/terraform-outputs/README.md) | 15 min | Expose the ALB DNS name and cluster names as outputs, and query them with `terraform output` |
| [Write Terraform From Scratch](next_steps/write-terraform-variables/README.md) | 30 min | Replace the `sed` workflow with a declared input variable — author Terraform by hand |
| [Build & Deploy a Custom Image](next_steps/ecr-custom-image/README.md) | 45 min | Create an ECR repository, build a custom Docker image, push to ECR, deploy via Terraform |
| [ECS Service Auto Scaling](next_steps/auto-scaling/README.md) | 30 min | Add a target-tracking auto scaling policy that scales tasks based on CPU utilization |

## Course Metrics

- **208 minutes** of hands-on lab time (5 core labs)
- **111 minutes** of theory, presentation, recaps, and wrap-up
- **319 minutes** of instruction in total, inside a 330-minute window
- **120 minutes** of bonus lab content (4 next-steps labs)
- **42 slides** in the Reveal.js deck
- **2 deployment methods**: AWS Console and Terraform
- **Same architecture, two approaches**: build it manually, then automate it

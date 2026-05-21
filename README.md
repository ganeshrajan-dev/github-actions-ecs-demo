# GitHub Actions ECS Demo

End-to-end CI/CD pipeline: **Terraform infrastructure** + **Docker build & deploy to AWS ECS Fargate**.

## Architecture

```
GitHub Push/PR
      │
      ├── terraform.yml ──► Terraform validate/plan/apply ──► AWS Infra (VPC, ALB, ECS, ECR)
      │
      └── deploy.yml ──► Docker build ──► Push to ECR ──► Update ECS Service
```

## What Gets Created in AWS

| Resource | Purpose |
|----------|---------|
| VPC + 2 Public Subnets | Network isolation |
| Internet Gateway + Routes | Public internet access |
| ECR Repository | Store Docker images |
| ECS Fargate Cluster | Run containers serverless |
| ECS Task Definition | Container config (CPU, memory, ports) |
| ECS Service | Keeps desired task count running |
| Application Load Balancer | Routes HTTP traffic to containers |
| Security Groups | ALB: allows port 80; ECS: allows traffic from ALB only |
| IAM Role | ECS task execution (pull images, write logs) |
| CloudWatch Log Group | Container logs |

## Prerequisites

- AWS Account with IAM user that has permissions for VPC, ECS, ECR, ALB, IAM, CloudWatch
- GitHub repository
- Terraform CLI (for local testing)

## Setup Steps

### 1. Push this code to a GitHub repository

```bash
cd github-actions-ecs-demo
git init
git add .
git commit -m "Initial commit: Terraform + GitHub Actions ECS pipeline"
git remote add origin https://github.com/YOUR_USER/github-actions-ecs-demo.git
git push -u origin main
```

### 2. Configure GitHub Secrets

Go to your repo → **Settings → Secrets and variables → Actions → New repository secret**

| Secret Name | Value |
|-------------|-------|
| `AWS_ACCESS_KEY_ID` | Your IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | Your IAM user secret key |

### 3. First Run: Deploy Infrastructure

The first time, you need to run Terraform to create the ECR repo before you can push images.

**Option A — Run locally first:**
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

**Option B — Push a change to `terraform/` on main branch:**
The `terraform.yml` workflow will auto-apply on push to main.

### 4. Push Initial Docker Image

After ECR exists, push a change to `app/` on the main branch. The `deploy.yml` workflow will:
1. Build the Docker image
2. Push it to ECR
3. Force ECS to deploy the new image

### 5. Access Your App

After deployment, get the ALB DNS name:
```bash
terraform -chdir=terraform output alb_dns_name
```
Visit `http://<alb-dns-name>` in your browser — you should see:
```json
{"message":"Hello from ECS!","version":"1.0.0","timestamp":"..."}
```

## Workflow Details

### `terraform.yml` — Infrastructure CI/CD

| Trigger | What happens |
|---------|-------------|
| PR to main (terraform/ changed) | fmt check → init → validate → plan → post plan as PR comment |
| Push to main (terraform/ changed) | fmt check → init → validate → apply |

### `deploy.yml` — App Build & Deploy

| Trigger | What happens |
|---------|-------------|
| Push to main (app/ changed) | checkout → AWS login → ECR login → Docker build → push → ECS force deploy |
| Manual (workflow_dispatch) | Same as above |

## Hands-On Learning Exercises

1. **Create a PR** — change something in `terraform/` and see the plan posted as a comment
2. **Merge it** — watch Terraform apply run automatically
3. **Modify the app** — change the message in `app/index.js`, push, watch the full deploy cycle
4. **Add a new route** — add `GET /info` to the Express app, push, verify it works via ALB
5. **Break something intentionally** — introduce a Terraform syntax error and see the PR check fail
6. **Add an environment** — create `terraform/environments/staging/` to practice multi-env

## Cleanup

To avoid AWS charges:
```bash
cd terraform
terraform destroy
```

## Cost Estimate

Running this in dev (1 Fargate task, ALB) costs approximately **$1-2/day**. Remember to destroy when not practicing.

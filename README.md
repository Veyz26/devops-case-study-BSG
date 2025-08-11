# BSG DevOps Case Study - Submission Repo

This repository contains a complete starter implementation for the BSG DevOps engineering case study.
It includes Terraform infra to run in AWS (af-south-1), a simple Java payment app, a private Geth provider, and a GitHub Actions pipeline that builds images, runs SAST (CodeQL), pushes to ECR, and applies Terraform.

## Structure
- `infrastructure/` - Terraform code (VPC, ECR, ECS Fargate, ALB, CloudWatch)
- `payment-platform/` - Maven Java app and Dockerfile
- `geth-provider/` - docker-compose.yml for local testing of Geth
- `.github/workflows/ci-cd.yml` - GitHub Actions workflow
- `cleanup.sh` - helper script to tear down resources locally / instructions

## Quick local test (recommended before running in AWS sandbox)
1. Start Geth locally:
   ```
   cd geth-provider
   docker-compose up -d
   ```

2. Build the Java app:
   ```
   cd payment-platform
   mvn clean package
   ```

3. Run the Java app against local geth:
   ```
   GETH_URL=http://localhost:8545 java -jar target/payment-app-1.0.0-jar-with-dependencies.jar
   ```

You should see log entries like:
```
2025-... | TxID: ... | Value: 100 | Result: ...
```

## Deploying to AWS (sandbox) - summary
1. Ensure you have AWS credentials configured (sandbox). Set env vars or use GitHub Secrets in the repo:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_ACCOUNT_ID`
   - `ECR_PAYMENT_REPO` (e.g. bsg-payment-payment)
   - `ECR_GETH_REPO` (e.g. bsg-payment-geth)

2. Terraform backend: optionally configure remote state in `infrastructure/provider.tf` comment block.

3. Push code to GitHub (main branch). The workflow will:
   - Run CodeQL SAST
   - Build payment image and push to ECR
   - Tag & push geth image to ECR
   - Run `terraform apply` to create resources and deploy ECS services

## Important security notes
- S3 bucket for audit logs should enable object lock & encryption (see Terraform comments). You may need to enable object lock when creating the bucket (console/API).
- For secrets, replace plain text environment usage with AWS Secrets Manager or Parameter Store and grant tasks the minimum required IAM permissions.

## Cleanup
- Use `terraform destroy` in `infrastructure/` to remove infra (or run cleanup steps listed at the bottom of this README).
- Always ensure `desired_count=0` for ECS services before deleting if you want zero downtime mistakes.

## Additional improvements you can add
- Push transaction logs to CloudWatch Logs and an S3 audit bucket via a Lambda or sidecar container.
- Implement PutMetricData in the app to report `Payments.TotalAmount`.
- Add DAST stage (OWASP ZAP) in GitHub Actions.

## Documentation & Handover Checklist

- **Project Overview:**
  - This project deploys a Java payment app and a Geth provider to AWS using ECS Fargate, ECR, ALB, and Terraform.
- **Architecture Diagram:**
  - (Add a diagram if available)
- **Setup Instructions:**
  - See above for local and AWS deployment steps.
- **Secrets Management:**
  - Sensitive values (e.g., DB_PASSWORD) are stored in AWS Secrets Manager and injected into ECS tasks via the `secrets` block in the task definition.
  - To update a secret, use the AWS Console or CLI to update the value in Secrets Manager.
- **CI/CD Pipeline:**
  - (Describe your pipeline, e.g., GitHub Actions in `.github/workflows/ci-cd.yml` builds, tests, pushes images, and applies Terraform.)
- **Monitoring & Alerts:**
  - CloudWatch dashboards and alarms are set up for ECS, ALB, and application metrics.
  - Alarms include CPU, memory, and ALB 5xx errors.
- **Scaling & Cost:**
  - ECS service desired count and Fargate resource sizes can be adjusted in Terraform.
- **Cleanup:**
  - Run `terraform destroy` and `cleanup.sh` to remove all resources.
- **Contact:**
  - (Add contact info for support or handover)

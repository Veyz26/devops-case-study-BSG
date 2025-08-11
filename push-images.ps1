# PowerShell script to build and push Docker images to AWS ECR for payment-platform and geth-provider

# Define AWS region, account ID, and project name
$region = "af-south-1"
$accountId = "009160066839"  # <-- Replace with your AWS Account ID
$project = "bsg-payment"         # <-- Change if your project variable is different

# Authenticate Docker to ECR
aws ecr get-login-password --region $region | docker login --username AWS --password-stdin "$accountId.dkr.ecr.$region.amazonaws.com"

# Build and push payment-platform image
cd "$PSScriptRoot/payment-platform"
Write-Host "Building payment-platform Docker image..."
docker build -t payment-platform .
docker tag payment-platform:latest "$accountId.dkr.ecr.$region.amazonaws.com/$project-payment:latest"
Write-Host "Pushing payment-platform image to ECR..."
docker push "$accountId.dkr.ecr.$region.amazonaws.com/$project-payment:latest"

# Build and push geth-provider image (using public Ethereum image as base)
cd "$PSScriptRoot/geth-provider"
Write-Host "Building geth-provider Docker image..."
docker pull ethereum/client-go:stable
# Tag and push the public image to your ECR
docker tag ethereum/client-go:stable "$accountId.dkr.ecr.$region.amazonaws.com/$project-geth:latest"
Write-Host "Pushing geth-provider image to ECR..."
docker push "$accountId.dkr.ecr.$region.amazonaws.com/$project-geth:latest"

Write-Host "Docker images built and pushed to ECR successfully!"

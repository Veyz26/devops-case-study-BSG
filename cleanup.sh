#!/bin/bash
# Local helper: destroy terraform infra (if backend is not remote) and give hints for ECS cleanup.
set -e
echo "This script helps you with cleanup steps. It assumes you run terraform destroy in infrastructure/ if you applied."
echo "To destroy terraform infra (from repo root):"
echo "  cd infrastructure && terraform destroy -auto-approve"
echo ""
echo "To scale down ECS services manually via AWS CLI (example names):"
echo "  aws ecs update-service --cluster bsg-payment-cluster --service bsg-payment-payment-svc --desired-count 0 --region af-south-1"
echo "  aws ecs update-service --cluster bsg-payment-cluster --service bsg-payment-geth-svc --desired-count 0 --region af-south-1"
echo ""
echo "To remove local geth container:"
echo "  cd geth-provider && docker-compose down -v"

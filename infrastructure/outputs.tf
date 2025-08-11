output "alb_dns" {
  value = aws_lb.alb.dns_name
}
output "ecr_payment_repo" {
  value = aws_ecr_repository.payment_repo.repository_url
}
output "ecr_geth_repo" {
  value = aws_ecr_repository.geth_repo.repository_url
}

resource "aws_cloudwatch_log_group" "payment_logs" {
  name              = "/ecs/${var.project}-payment"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "geth_logs" {
  name              = "/ecs/${var.project}-geth"
  retention_in_days = 30
}

data "aws_iam_policy_document" "ecs_task_assume" {
statement {
  principals {
    type        = "Service"
    identifiers = ["ecs-tasks.amazonaws.com"]
  }
  actions = ["sts:AssumeRole"]
}
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project}-ecs-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

resource "aws_iam_role_policy_attachment" "exec_attach" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Duplicate ECS service and task definitions removed. See ecr-ecs-alb.tf for current ECS resources.

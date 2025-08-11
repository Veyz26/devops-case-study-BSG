resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecr_repository" "payment_repo" {
  name = "${var.project}-payment"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "geth_repo" {
  name = "${var.project}-geth"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.project}-cluster"
}

resource "aws_security_group" "alb_sg" {
  name   = "${var.project}-alb-sg"
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_sg" {
  name   = "${var.project}-ecs-sg"
  vpc_id = module.vpc.vpc_id
  # allow ALB -> ECS (HTTP)
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "allow ALB to payment task"
  }
  # allow internal traffic (e.g., from payment to geth)
  ingress {
    from_port   = 8545
    to_port     = 8545
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "allow internal access to geth"
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "alb" {
  name               = "${var.project}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_target_group" "payment_tg" {
  name     = "${var.project}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
  target_type = "ip"
  health_check {
    path                = "/health"
    matcher             = "200-399"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payment_tg.arn
  }
}

resource "aws_ecs_task_definition" "payment_task" {
  family                   = "${var.project}-payment"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions    = jsonencode([
    {
      name      = "payment"
      image     = "${aws_ecr_repository.payment_repo.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project}-payment"
          awslogs-region        = "af-south-1"
          awslogs-stream-prefix = "ecs"
        }
      }
      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = aws_secretsmanager_secret.db_password.arn
        }
      ]
    }
  ])
}

resource "aws_ecs_task_definition" "geth_task" {
  family                   = "${var.project}-geth"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions    = jsonencode([
    {
      name      = "geth"
      image     = "${aws_ecr_repository.geth_repo.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8545
          hostPort      = 8545
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project}-geth"
          awslogs-region        = "af-south-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "payment_service" {
  name            = "${var.project}-payment-svc"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.payment_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  network_configuration {
    subnets          = module.vpc.public_subnets
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.payment_tg.arn
    container_name   = "payment"
    container_port   = 80
  }
  depends_on = [aws_lb_listener.http]
}

resource "aws_ecs_service" "geth_service" {
  name            = "${var.project}-geth-svc"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.geth_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  network_configuration {
    subnets          = module.vpc.public_subnets
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
}

resource "aws_secretsmanager_secret" "db_password" {
  name = "${var.project}-db-password"
}

resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = "supersecretpassword" # Change this to your actual secret
}

# Add this to your ECS task definition's container_definitions (as JSON):
# "secrets": [
#   {
#     "name": "DB_PASSWORD",
#     "valueFrom": "${aws_secretsmanager_secret.db_password.arn}"
#   }
# ]

resource "aws_cloudwatch_metric_alarm" "alb_5xx_alarm" {
  alarm_name          = "${var.project}-ALB-5xx-Alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "ALB is returning 5xx errors"
  dimensions = {
    LoadBalancer = aws_lb.alb.arn_suffix
  }
}

# Documentation checklist (add to README.md):
# - Project Overview
# - Architecture Diagram (optional)
# - Setup Instructions
# - Secrets Management
# - CI/CD Pipeline
# - Monitoring & Alerts
# - Scaling & Cost
# - Cleanup
# - Contact

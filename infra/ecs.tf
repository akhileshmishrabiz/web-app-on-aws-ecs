data "template_file" "python_app" {
  template = file("task-definitions/service.json.tpl")
  vars = {
    aws_ecr_repository            = aws_ecr_repository.python_app.repository_url
    tag                           = "latest"
    container_name                = var.app_name
    aws_cloudwatch_log_group_name = aws_cloudwatch_log_group.python_app.name
    database_address              = aws_db_instance.postgres.address
    database_name                 = aws_db_instance.postgres.name
    postgres_username             = aws_db_instance.postgres.username
    postgres_password             = "${data.aws_secretsmanager_secret.postgresql_password_secret.id}:POSTGRES_PASSWORD::"
  }
}

resource "aws_ecs_task_definition" "service" {
  family                   = "${var.app_name}-${var.environment}"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = 256
  memory                   = 2048
  requires_compatibilities = ["FARGATE"]
  container_definitions    = data.template_file.python_app.rendered
  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

resource "aws_ecs_service" "staging" {
  name                       = var.environment
  cluster                    = aws_ecs_cluster.staging.id
  task_definition            = aws_ecs_task_definition.service.arn
  desired_count              = 1
  deployment_maximum_percent = 250
  launch_type                = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.staging.arn
    container_name   = var.app_name
    container_port   = 5000
  }

  depends_on = [aws_lb_listener.https_forward, aws_iam_role_policy.ecs_task_execution_role]

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

resource "aws_ecs_cluster" "staging" {
  name = "${var.app_name}-cluster"
    setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "rds_shrink" {
  #checkov:skip=CKV_AWS_158: CWL get auto encrypted
  name              = "/aws/ecs/${var.environment}-rds-shrink"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_query_definition" "rds_shrink_logs" {
  name = "${var.environment}/rds-shrink"

  log_group_names = [
    aws_cloudwatch_log_group.rds_shrink.name,
  ]

  query_string = <<EOF
filter @message not like /.+Waiting.+/
| fields @timestamp, @message
| sort @timestamp desc
| limit 200
EOF
}



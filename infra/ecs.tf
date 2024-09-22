data "template_file" "python_app" {
  template = file("task-definitions/service.json.tpl")
  vars = {
    aws_ecr_repository            = aws_ecr_repository.python_app.repository_url
    tag                           = "latest"
    container_name                = var.app_name
    aws_cloudwatch_log_group_name = aws_cloudwatch_log_group.ecs.name
    database_address              = aws_db_instance.postgres.address
    database_name                 = aws_db_instance.postgres.db_name
    postgres_username             = aws_db_instance.postgres.username
    postgres_password             = random_password.dbs_random_string.result
  }
}

resource "aws_ecs_task_definition" "main" {
  family                   = "${var.environment}-${var.app_name}"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = 2048
  memory                   = 4096
  requires_compatibilities = ["FARGATE"]
  container_definitions    = data.template_file.python_app.rendered
  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}



resource "aws_ecs_service" "main" {
  name                       = "${var.environment}-${var.app_name}-service"
  cluster                    = aws_ecs_cluster.main.id
  task_definition            = aws_ecs_task_definition.main.arn
  desired_count              = 1
  deployment_maximum_percent = 250
  launch_type                = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb.arn
    container_name   = var.app_name
    container_port   = 8000
  }

  depends_on = [aws_lb_listener.https_forward, aws_iam_role_policy.ecs_task_execution_role]

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-${var.app_name}-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

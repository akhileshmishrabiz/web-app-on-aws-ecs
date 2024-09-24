data "template_file" "services" {
  for_each = { for service in local.ecs_services : service.name => service }
  template = file(each.value.template_file)
  vars     = each.value.vars
}

resource "aws_ecs_task_definition" "services" {
  for_each                 = { for service in local.ecs_services : service.name => service }
  family                   = "${var.environment}-${each.key}"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  requires_compatibilities = ["FARGATE"]
  container_definitions    = data.template_file.services[each.key].rendered
  tags = {
    Environment = var.environment
    Application = each.key
  }
}

resource "aws_ecs_service" "flask_app_service" {
  name                       = "${var.environment}-flask-app-service"
  cluster                    = aws_ecs_cluster.main.id
  task_definition            = aws_ecs_task_definition.services["flask-app"].arn
  desired_count              = 1
  deployment_maximum_percent = 250
  launch_type                = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = true
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.main.arn
    service {
      client_alias {
        port     = 8080
        dns_name = "app"
      }
      port_name      = "app"
      discovery_name = "app"
    }
  }
  depends_on = [
    aws_iam_role_policy.ecs_task_execution_role,
    aws_ecs_service.redis_service
  ]

  tags = {
    Environment = var.environment
    Application = "flask-app"
  }
}

resource "aws_ecs_service" "nginx_service" {
  name                       = "${var.environment}-nginx-service"
  cluster                    = aws_ecs_cluster.main.id
  task_definition            = aws_ecs_task_definition.services["nginx"].arn
  desired_count              = 1
  deployment_maximum_percent = 250
  launch_type                = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.public.*.id
    assign_public_ip = true
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.main.arn
    service {
      client_alias {
        port     = 80
        dns_name = "nginx"
      }
      port_name      = "nginx"
      discovery_name = "nginx"
    }
  }

  # load_balancer {
  #   target_group_arn = aws_lb_target_group.alb.arn
  #   container_name   = "nginx"
  #   container_port   = 80
  # }

  depends_on = [
    aws_lb_listener.https_forward,
    aws_iam_role_policy.ecs_task_execution_role,
    aws_ecs_service.flask_app_service
  ]

  tags = {
    Environment = var.environment
    Application = "nginx"
  }
}

resource "aws_ecs_service" "redis_service" {
  name                       = "${var.environment}-redis-service"
  cluster                    = aws_ecs_cluster.main.id
  task_definition            = aws_ecs_task_definition.services["redis"].arn
  desired_count              = 1
  deployment_maximum_percent = 250
  launch_type                = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = true
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.main.arn
    service {
      client_alias {
        port     = 6379
        dns_name = "redis"
      }
      port_name      = "redis"
      discovery_name = "redis"
    }
  }

  depends_on = [
    aws_iam_role_policy.ecs_task_execution_role,
  ]

  tags = {
    Environment = var.environment
    Application = "redis"
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-${var.app_name}-cluster"
  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.main.arn
  }
}

resource "aws_service_discovery_http_namespace" "main" {
  name        = "${var.environment}-${var.app_name}-namespace"
  description = "Dev name space"
}
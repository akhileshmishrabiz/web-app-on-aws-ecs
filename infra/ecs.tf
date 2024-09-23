data "template_file" "services" {
  for_each = { for service in local.ecs_services : service.name => service }
  template = file(each.value.template_file)
  vars     = each.value.vars
}

resource "aws_ecs_task_definition" "services" {
  for_each                = { for service in local.ecs_services : service.name => service }
  family                  = "${var.environment}-${each.key}"
  network_mode            = "awsvpc"
  execution_role_arn      = aws_iam_role.ecs_task_execution_role.arn
  cpu                     = each.value.cpu
  memory                  = each.value.memory
  requires_compatibilities = ["FARGATE"]
  container_definitions   = data.template_file.services[each.key].rendered
  tags = {
    Environment = var.environment
    Application = each.key
  }
}

resource "aws_ecs_service" "flask_app_service" {
  name                      = "${var.environment}-flask-app-service"
  cluster                   = aws_ecs_cluster.main.id
  task_definition           = aws_ecs_task_definition.services["flask-app"].arn
  desired_count             = 1
  deployment_maximum_percent = 250
  launch_type               = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = true
  }

  service_connect {
    namespace = local.ecs_services[0].service_connect.namespace
    services = [
      for svc in local.ecs_services[0].service_connect.services : {
        port_name      = svc.port_name
        port           = svc.port
        discovery_name = svc.discovery_name
      }
    ]
  }

  tags = {
    Environment = var.environment
    Application = "flask-app"
  }
}

resource "aws_ecs_service" "nginx_service" {
  name                      = "${var.environment}-nginx-service"
  cluster                   = aws_ecs_cluster.main.id
  task_definition           = aws_ecs_task_definition.services["nginx"].arn
  desired_count             = 1
  deployment_maximum_percent = 250
  launch_type               = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = true
  }

  service_connect {
    namespace = local.ecs_services[1].service_connect.namespace
    services = [
      for svc in local.ecs_services[1].service_connect.services : {
        port_name      = svc.port_name
        port           = svc.port
        discovery_name = svc.discovery_name
      }
    ]
  }

  dynamic "load_balancer" {
    for_each = local.ecs_services[1].container_name == "nginx" && local.ecs_services[1].vars.port == 80 ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.alb.arn
      container_name   = local.ecs_services[1].container_name
      container_port   = local.ecs_services[1].vars.port
    }
  }

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
  name                      = "${var.environment}-redis-service"
  cluster                   = aws_ecs_cluster.main.id
  task_definition           = aws_ecs_task_definition.services["redis"].arn
  desired_count             = 1
  deployment_maximum_percent = 250
  launch_type               = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = true
  }

  service_connect {
    namespace = local.ecs_services[2].service_connect.namespace
    services = [
      for svc in local.ecs_services[2].service_connect.services : {
        port_name      = svc.port_name
        port           = svc.port
        discovery_name = svc.discovery_name
      }
    ]
  }

  depends_on = [
    aws_iam_role_policy.ecs_task_execution_role,
    aws_ecs_service.nginx_service
  ]

  tags = {
    Environment = var.environment
    Application = "redis"
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-${var.app_name}-cluster"

  settings {
    name  = "containerInsights"
    value = "enabled"
  }
}
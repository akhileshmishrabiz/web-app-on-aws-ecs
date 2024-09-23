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

resource "aws_ecs_service" "services" {
  for_each                  = { for service in local.ecs_services : service.name => service }
  name                      = "${var.environment}-${each.key}-service"
  cluster                   = aws_ecs_cluster.main.id
  task_definition           = aws_ecs_task_definition.services[each.key].arn
  desired_count             = 1
  deployment_maximum_percent = 250
  launch_type               = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = true
  }

  service_connect {
    namespace = each.value.service_connect.namespace
    services = [
      for svc in each.value.service_connect.services : {
        port_name      = svc.port_name
        port           = svc.port
        discovery_name = svc.discovery_name
      }
    ]
  }

  dynamic "load_balancer" {
    for_each = each.value.container_name == "nginx" && each.value.container_port == 80 ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.alb.arn
      container_name   = each.value.container_name
      container_port   = each.value.container_port
    }
  }

  depends_on = [
    aws_lb_listener.https_forward,
    aws_iam_role_policy.ecs_task_execution_role,
    each.key == "nginx" ? aws_ecs_service.services["flask-app"] : null,
    each.key == "redis" ? aws_ecs_service.services["nginx"] : null
  ]

  tags = {
    Environment = var.environment
    Application = each.key
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-${var.app_name}-cluster"
}
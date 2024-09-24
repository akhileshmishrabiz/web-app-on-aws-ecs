locals {
  db_data = {
    allocated_storage       = 30
    max_allocated_storage   = 100
    engine_version          = "14.10"
    instance_class          = "db.t3.small"
    ca_cert_name            = "rds-ca-2019"
    backup_retention_period = 7
    db_name                 = "mydb"
    cloudwatch_logs         = ["postgresql", "upgrade"]
  }

  ecs_services = [
    {
      name          = "flask-app"
      cpu           = 1024
      memory        = 2048
      template_file = "task-definitions/flask-service.json.tpl"
      vars = {
        aws_ecr_repository            = aws_ecr_repository.python_app.repository_url
        tag                           = "latest"
        container_name                = "flask-app"
        aws_cloudwatch_log_group_name = "/aws/ecs/${var.environment}-flask-app"
        database_address              = aws_db_instance.postgres.address
        database_name                 = aws_db_instance.postgres.db_name
        postgres_username             = aws_db_instance.postgres.username
        postgres_password             = random_password.dbs_random_string.result
        environment                   = var.environment
      }
    },
    {
      name          = "nginx"
      cpu           = 1024
      memory        = 2048
      template_file = "task-definitions/nginx-service.json.tpl"
      vars = {
        aws_ecr_repository            = "366140438193.dkr.ecr.ap-south-1.amazonaws.com/nginx"
        tag                           = "latest"
        container_name                = "nginx"
        aws_cloudwatch_log_group_name = "/aws/ecs/${var.environment}-nginx"
        environment                   = var.environment
      }
    },
    {
      name          = "redis"
      cpu           = 1024
      memory        = 2048
      template_file = "task-definitions/redis-service.json.tpl"
      vars = {
        aws_ecr_repository            = "redis"
        tag                           = "latest"
        container_name                = "redis"
        aws_cloudwatch_log_group_name = "/aws/ecs/${var.environment}-redis"
        environment                   = var.environment
      }
    }
  ]
}


resource "aws_cloudwatch_log_group" "ecs" {
  for_each = { for service in local.ecs_services : service.name => service }

  name              = "/aws/ecs/${var.environment}-${each.value.name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_query_definition" "ecs" {
  for_each = { for service in local.ecs_services : service.name => service }

  name = "${var.environment}-${each.value.name}"

  log_group_names = [
    aws_cloudwatch_log_group.ecs[each.key].name,
  ]

  query_string = <<-EOF
    filter @message not like /.+Waiting.+/
    | fields @timestamp, @message
    | sort @timestamp desc
    | limit 200
  EOF
}
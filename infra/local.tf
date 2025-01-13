locals {
  db_data = {
    allocated_storage       = "30"
    max_allocated_storage   = 100
    engine_version          = "14.10"
    instance_class          = "db.t3.small"
    ca_cert_name            = "rds-ca-rsa2048-g1"
    backup_retention_period = 7
    db_name                 = "mydb"
    cloudwatch_logs         = ["postgresql", "upgrade"]
  }

  ecs_services = [
    {
      name          = "flask"
      cpu           = var.flask_app_cpu
      memory        = var.flask_app_memory
      template_file = var.flask_app_template_file
      vars = {
        aws_ecr_repository            = aws_ecr_repository.python_app.repository_url
        tag                           = var.flask_app_tag
        container_name                = var.flask_app_container_name
        aws_cloudwatch_log_group_name = "/aws/ecs/${var.environment}-flask"
        database_address              = var.environment == "dev" ? aws_db_instance.postgres[0].address : aws_rds_cluster.postgres[0].endpoint
        database_name                 = var.environment == "dev" ? aws_db_instance.postgres[0].db_name : aws_rds_cluster.postgres[0].database_name
        postgres_username             = var.environment == "dev" ? aws_db_instance.postgres[0].username : aws_rds_cluster.postgres[0].master_username
        postgres_password             = random_password.dbs_random_string.result
        database_url                  = var.environment == "dev" ? "postgres://${aws_db_instance.postgres[0].username}:${random_password.dbs_random_string.result}@${aws_db_instance.postgres[0].address}:${aws_db_instance.postgres[0].port}/${aws_db_instance.postgres[0].db_name}" : "postgres://${aws_rds_cluster.postgres[0].master_username}:${random_password.dbs_random_string.result}@${aws_rds_cluster.postgres[0].endpoint}:${aws_rds_cluster.postgres[0].port}/${aws_rds_cluster.postgres[0].database_name}"
        environment                   = var.environment
      }
    },
    {
      name          = "nginx"
      cpu           = var.nginx_cpu
      memory        = var.nginx_memory
      template_file = var.nginx_template_file
      vars = {
        aws_ecr_repository            = aws_ecr_repository.nginx.repository_url
        tag                           = var.nginx_tag
        container_name                = var.nginx_container_name
        aws_cloudwatch_log_group_name = "/aws/ecs/${var.environment}-nginx"
        environment                   = var.environment
      }
    },
    {
      name          = "redis"
      cpu           = var.redis_cpu
      memory        = var.redis_memory
      template_file = var.redis_template_file
      vars = {
        aws_ecr_repository            = aws_ecr_repository.redis.repository_url
        tag                           = var.redis_tag
        container_name                = var.redis_container_name
        aws_cloudwatch_log_group_name = "/aws/ecs/${var.environment}-redis"
        environment                   = var.environment
      }
    }
  ]

  flask_deploy_data = {
    IMAGE_NAME : "${var.app_name}-image"
    ECR_REGISTRY : "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
    ECR_REPOSITORY : "${var.environment}-${var.app_name}-flask"
    ACCOUNT_ID : data.aws_caller_identity.current.account_id
    ECS_CLUSTER : "${var.environment}-${var.app_name}-cluster"
    ECS_REGION : data.aws_region.current.name
    ECS_SERVICE : "${var.environment}-${var.app_name}-flask-service"
    ECS_TASK_DEFINITION : "${var.environment}-${var.app_name}-flask"
    ECS_APP_CONTAINER_NAME : var.flask_app_container_name

  }
}


resource "aws_secretsmanager_secret" "app_deploy_data" {
  name        = "${var.environment}-${var.app_name}-flask-deploy-data"
  description = "Deployment data for the Flask app"
}

resource "aws_secretsmanager_secret_version" "app_deploy_data_version" {
  secret_id     = aws_secretsmanager_secret.app_deploy_data.id
  secret_string = jsonencode(local.flask_deploy_data)
}

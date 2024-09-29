locals {
  db_data = {
    allocated_storage       = var.db_allocated_storage
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
        database_url                  = aws_secretsmanager_secret_version.dbs_secret_val.secret_string
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
        aws_ecr_repository            = "366140438193.dkr.ecr.ap-south-1.amazonaws.com/redis"
        tag                           = "latest"
        container_name                = "redis"
        aws_cloudwatch_log_group_name = "/aws/ecs/${var.environment}-redis"
        environment                   = var.environment
      }
    }
  ]

  app_deploy_data = {
    IMAGE_NAME : "flask-app"
    ECR_REGISTRY : "366140438193.dkr.ecr.ap-south-1.amazonaws.com"
    ECR_REPOSITORY : "${var.environment}-app"
    ACCOUNT_ID : "366140438193"
    ECS_CLUSTER : "${var.environment}-app-cluster"
    ECS_REGION : "ap-south-1"
    ECS_SERVICE : "${var.environment}-flask-app-service"
    ECS_TASK_DEFINITION : "${var.environment}-flask-app"
    ECS_APP_CONTAINER_NAME : "flask-app"
  }
}


resource "aws_secretsmanager_secret" "app_deploy_data" {
  name        = "${var.environment}-app-deploy-data"
  description = "Deployment data for the Flask app"
}

resource "aws_secretsmanager_secret_version" "app_deploy_data_version" {
  secret_id     = aws_secretsmanager_secret.app_deploy_data.id
  secret_string = jsonencode(local.app_deploy_data)
}

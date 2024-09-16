resource "aws_kms_key" "rds_kms" {
  description             = "KMS key for RDS and Secrets Manager"
  deletion_window_in_days = 10

  tags = {
    Name        = "rds-kms-key"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "rds_kms_alias" {
  name          = "alias/rds-kms-key"
  target_key_id = aws_kms_key.rds_kms.id
}

resource "aws_db_instance" "postgres" {
  identifier            = "${var.environment}-${var.app_name}-db"
  allocated_storage     = lookup(local.db_data, "allocated_storage", var.db_default_settings.allocated_storage)
  max_allocated_storage = lookup(local.db_data, "max_allocated_storage", var.db_default_settings.max_allocated_storage)
  engine                =  "postgres"
  engine_version        = lookup(local.db_data, "engine_version", var.db_default_settings.engine_version)
  instance_class        = lookup(local.db_data, "instance_class", var.db_default_settings.instance_class)
  username              = "postgres"
  password              = random_password.dbs_random_string.result
  port                  = 5432
  publicly_accessible   = false
  db_subnet_group_name  = aws_db_subnet_group.postgres.id
  ca_cert_identifier    = lookup(local.db_data, "ca_cert_name", var.db_default_settings.ca_cert_name)
  storage_encrypted     = true
  storage_type          = "gp3"
  kms_key_id            = aws_kms_key.rds_kms.arn
  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  backup_retention_period         = lookup(local.db_data, "backup_retention_period", var.db_default_settings.backup_retention_period)
  db_name                         = lookup(local.db_data, "db_name", var.db_default_settings.db_name)
  auto_minor_version_upgrade      = true
  deletion_protection             = true
  monitoring_interval             = 60
  enabled_cloudwatch_logs_exports = lookup(local.db_data, "cloudwatch_logs", ["postgresql", "upgrade"])
  copy_tags_to_snapshot           = true

  tags = {
    environment = var.environment
  }
}

resource "aws_secretsmanager_secret" "dbs_secret" {
  name                    = "db/${var.environment}"
  description             = "DB link"
  kms_key_id              = aws_kms_key.rds_kms.arn
  recovery_window_in_days = 7
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_secretsmanager_secret_version" "dbs_secret_val" {
  secret_id     = aws_secretsmanager_secret.dbs_secret.id
  secret_string = "postgres://${var.db_default_settings}:${random_password.dbs_random_string.result}@${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${aws_db_instance.postgres.db_name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_password" "dbs_random_string" {
  length  = 16
  special = true
}

resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg"
  description = "RDS security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-rds-sg"
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "allow_ecs_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.ecs_tasks.id
}



resource "aws_db_subnet_group" "postgres" {
  name       = "${var.environment}-${var.app_name}-db-subnet-group"
  description = "Subnet group for RDS instance"
  subnet_ids = aws_subnet.rds.*.id

  tags = {
    Name        = "${var.environment}-${var.app_name}-db-subnet-group"
    Environment = var.environment
  }
}
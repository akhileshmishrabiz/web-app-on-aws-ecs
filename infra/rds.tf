resource "aws_db_instance" "dbs" {
  identifier            = "${var.environment}-db"
  allocated_storage     = lookup(each.value, "allocated_storage", var.db_default_settings.allocated_storage)
  max_allocated_storage = lookup(each.value, "max_allocated_storage", var.db_default_settings.max_allocated_storage)
  engine                = data.aws_rds_engine_version.postgresql[each.key].engine
  engine_version        = lookup(each.value, "engine_version", var.db_default_settings.engine_version)
  instance_class        = lookup(each.value, "instance_class", var.db_default_settings.instance_class)
  username              = postgres
  password              = random_password.dbs_random_string[each.key].result
  port                  = 5432
  publicly_accessible   = false
  db_subnet_group_name  = aws_db_subnet_group.dbs_subnet_group[each.key].id
  parameter_group_name  = aws_db_parameter_group.dbs_parameter_group[each.key].name
  ca_cert_identifier    = lookup(each.value, "ca_cert_name", var.db_default_settings.ca_cert_name)
  storage_encrypted     = true
  storage_type          = "gp3"
  # kms_key_id            = ""
  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  backup_retention_period               = lookup(each.value, "backup_retention_period", var.db_default_settings.backup_retention_period)
  db_name                               = lookup(each.value, "db_name", var.db_default_settings.db_name)
  # final_snapshot_identifier             = "db-final-snapshot-${var.environment}"
  auto_minor_version_upgrade            = true
  # backup_window                         = "01:30-02:00"
  # maintenance_window                    = ""
  deletion_protection                   = "true"
  monitoring_interval                   = 60
  monitoring_role_arn                   = aws_iam_role.rds_monitoring_role.arn
  enabled_cloudwatch_logs_exports       = lookup(each.value, "cloudwatch_logs", ["postgresql", "upgrade"])
  # iam_database_authentication_enabled   = true
  copy_tags_to_snapshot                 = true

  tags = {
    environment                    = var.environment
  }
}

resource "random_password" "dbs_random_string" {
  length           = 30
  lower            = true
  numeric          = true
  special          = true
  upper            = true
  override_special = "$^&*()_-+={}[]<>,.;"
}

resource "aws_secretsmanager_secret" "dbs_secret" {
  #checkov:skip=CKV2_AWS_57: Autorotate requires password update on DB TODO
  name                    = "db/${var.environment}-${each.key}"
  description             = "DB link"
  kms_key_id              = module.pdata.kms_arn
  recovery_window_in_days = 7
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_secretsmanager_secret_version" "dbs_secret_val" {
  secret_id     = aws_secretsmanager_secret.dbs_secret[each.key].id
  secret_string = "postgres://${var.db_default_settings}:${random_password.dbs_random_string.result}@${aws_db_instance.dbs.address}:${aws_db_instance.dbs.port}/${aws_db_instance.dbs.db_name}"

  lifecycle {
    create_before_destroy = true
  }
}




resource "aws_db_subnet_group" "postgres" {
  name       = "postgres-subnet"
  subnet_ids = aws_subnet.rds.*.id

  tags = {
    Name = "PostgreSQL DB subnet group"
  }
}

resource "aws_security_group" "rds" {
  name        = "rds-sg"
  vpc_id      = aws_vpc.default.id
  description = "allow inbound access from the ECS only"

  ingress {
    protocol        = "tcp"
    from_port       = 5432
    to_port         = 5432
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

    lifecycle {
    create_before_destroy = true
  }
  tags = {
    Environment = var.environment
  }
}
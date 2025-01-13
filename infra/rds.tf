resource "aws_kms_key" "rds_kms" {
  description             = "KMS key for RDS and Secrets Manager"
  deletion_window_in_days = 10

  tags = {
    Name        = "${var.environment}-rds-kms-key"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "rds_kms_alias" {
  name          = "alias/${var.environment}-rds-kms-key"
  target_key_id = aws_kms_key.rds_kms.id
}

# RDS instance for dev environment
resource "aws_db_instance" "postgres" {
  count                 = var.environment == "dev" ? 1 : 0
  identifier            = "${var.environment}-${var.app_name}-db"
  allocated_storage     = lookup(local.db_data, "allocated_storage", var.db_default_settings.allocated_storage)
  max_allocated_storage = lookup(local.db_data, "max_allocated_storage", var.db_default_settings.max_allocated_storage)
  engine                = data.aws_rds_engine_version.postgresql.engine
  engine_version        = lookup(local.db_data, "engine_version", var.db_default_settings.engine_version)
  instance_class        = lookup(local.db_data, "instance_class", var.db_default_settings.instance_class)
  username              = var.db_default_settings.db_admin_username
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
  enabled_cloudwatch_logs_exports = lookup(local.db_data, "cloudwatch_logs", ["postgresql", "upgrade"])
  copy_tags_to_snapshot           = true

  tags = {
    environment = var.environment
  }
}

# RDS cluster for non-dev environments
resource "aws_rds_cluster" "postgres" {
  count                   = var.environment != "dev" ? 1 : 0
  cluster_identifier      = "${var.environment}-${var.app_name}-cluster"
  engine                  = "aurora-postgresql"
  engine_version          = "14.9"
  master_username         = var.db_default_settings.db_admin_username
  master_password         = random_password.dbs_random_string.result
  database_name           = lookup(local.db_data, "db_name", var.db_default_settings.db_name)
  backup_retention_period = 7
  preferred_backup_window = "07:00-09:00"
  vpc_security_group_ids  = [aws_security_group.rds.id]
  db_subnet_group_name    = aws_db_subnet_group.postgres.id
   storage_encrypted       = true
  kms_key_id              = aws_kms_key.rds_kms.arn

  tags = {
    environment = var.environment
  }
}

resource "aws_rds_cluster_instance" "postgres_writer" {
  count                = var.environment != "dev" ? 1 : 0
  identifier           = "${var.environment}-${var.app_name}-writer"
  cluster_identifier   = aws_rds_cluster.postgres[0].id
  # instance_class       = lookup(local.db_data, "instance_class", var.db_default_settings.instance_class)
  instance_class = "db.r5.large"
  engine               = aws_rds_cluster.postgres[0].engine
  engine_version       = aws_rds_cluster.postgres[0].engine_version
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.postgres.id
  ca_cert_identifier   = lookup(local.db_data, "ca_cert_name", var.db_default_settings.ca_cert_name)
  apply_immediately    = true

  tags = {
    environment = var.environment
  }
}

resource "aws_rds_cluster_instance" "postgres_reader" {
  count                = var.environment != "dev" ? 1 : 0
  identifier           = "${var.environment}-${var.app_name}-reader"
  cluster_identifier   = aws_rds_cluster.postgres[0].id
  # instance_class       = lookup(local.db_data, "instance_class", var.db_default_settings.instance_class)
  instance_class = "db.r5.large"
  engine               = aws_rds_cluster.postgres[0].engine
  engine_version       = aws_rds_cluster.postgres[0].engine_version
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.postgres.id
  ca_cert_identifier   = lookup(local.db_data, "ca_cert_name", var.db_default_settings.ca_cert_name)
  apply_immediately    = true

  tags = {
    environment = var.environment
  }
}

resource "aws_secretsmanager_secret" "dbs_secret" {
  count                   = var.environment == "dev" ? 1 : 0
  name                    = "db/${var.environment}-${aws_db_instance.postgres[0].identifier}"
  description             = "DB link"
  kms_key_id              = aws_kms_key.rds_kms.arn
  recovery_window_in_days = 7
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_secretsmanager_secret_version" "dbs_secret_val" {
  count         = var.environment == "dev" ? 1 : 0
  secret_id     = aws_secretsmanager_secret.dbs_secret[0].id
  secret_string = "postgres://${var.db_default_settings.db_admin_username}:${random_password.dbs_random_string.result}@${aws_db_instance.postgres[0].address}:${aws_db_instance.postgres[0].port}/${aws_db_instance.postgres[0].db_name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_password" "dbs_random_string" {
  length           = 10
  special          = false
  override_special = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
}

resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg"
  vpc_id      = aws_vpc.main.id
  description = "allow inbound access from the ECS only"

  ingress {
    protocol        = "tcp"
    from_port       = 5432
    to_port         = 5432
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.ecs_tasks_flask.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "postgres" {
  name        = "${var.environment}-${var.app_name}-db-subnet-group"
  description = "Subnet group for RDS instance"
  subnet_ids  = aws_subnet.rds.*.id

  tags = {
    Name        = "${var.environment}-${var.app_name}-db-subnet-group"
    Environment = var.environment
  }
}
locals {
  db_data = {
    allocated_storage     = 30
    max_allocated_storage = 100
    engine_version        = "14.15"
    instance_class        = "db.t3.small"
    ca_cert_name          = "rds-ca-2019"
    backup_retention_period = 7
    db_name               = "mydb"
    cloudwatch_logs       = ["postgresql", "upgrade"]
  }
}
variable "app_name" {
  type    = string
  default = "app"
}

variable "environment" {
  type    = string
  default = "dev"
}
variable "db_allocated_storage" {
  type    = string
  default = "30"
}

variable "db_default_settings" {
  type = any
  default = {
    allocated_storage       = 10
    max_allocated_storage   = 50
    engine_version          = "14.5"
    instance_class          = "db.t3.micro"
    backup_retention_period = 2
    db_name                 = "postgres"
    ca_cert_name            = "rds-ca-rsa2048-g1"
    db_admin_username       = "postgres"
  }
}
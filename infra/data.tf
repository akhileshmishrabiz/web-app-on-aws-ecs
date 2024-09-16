
data "aws_availability_zones" "available_zones" {
  state = "available"
}

data "aws_rds_engine_version" "postgresql" {
  engine   = "postgres"
  version  = lookup(each.value, "engine_version", "14.10")
}
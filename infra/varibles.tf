variable "app_name" {
  type    = string
  default = "app"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "db_default_settings" {
  type = any
  default = {
    allocated_storage       = 30
    max_allocated_storage   = 50
    engine_version          = "14.5"
    instance_class          = "db.t3.micro"
    backup_retention_period = 2
    db_name                 = "postgres"
    ca_cert_name            = "rds-ca-rsa2048-g1"
    db_admin_username       = "postgres"
  }
}


########### microservices #################
#### flask app ####
variable "flask_app_cpu" {
  description = "CPU units for the flask-app service"
  type        = number
  default     = 1024
}

variable "flask_app_memory" {
  description = "Memory in MiB for the flask-app service"
  type        = number
  default     = 2048
}

variable "flask_app_template_file" {
  description = "Template file for the flask-app service"
  type        = string
  default     = "task-definitions/flask-service.json.tpl"
}

variable "flask_app_tag" {
  description = "Tag for the flask-app service"
  type        = string
  default     = "latest"
}

variable "flask_app_container_name" {
  description = "Container name for the flask-app service"
  type        = string
  default     = "flask-app"
}


##### nginx ####
variable "nginx_cpu" {
  description = "CPU units for the nginx service"
  type        = number
  default     = 1024
}

variable "nginx_memory" {
  description = "Memory in MiB for the nginx service"
  type        = number
  default     = 2048
}

variable "nginx_template_file" {
  description = "Template file for the nginx service"
  type        = string
  default     = "task-definitions/nginx-service.json.tpl"
}

variable "nginx_aws_ecr_repository" {
  description = "ECR repository URL for the nginx service"
  type        = string
  default     = "366140438193.dkr.ecr.ap-south-1.amazonaws.com/nginx"
}

variable "nginx_tag" {
  description = "Tag for the nginx service"
  type        = string
  default     = "latest"
}

variable "nginx_container_name" {
  description = "Container name for the nginx service"
  type        = string
  default     = "nginx"
}


#### redis ######

variable "redis_cpu" {
  description = "CPU units for the redis service"
  type        = number
  default     = 1024
}

variable "redis_memory" {
  description = "Memory in MiB for the redis service"
  type        = number
  default     = 2048
}

variable "redis_template_file" {
  description = "Template file for the redis service"
  type        = string
  default     = "task-definitions/redis-service.json.tpl"
}

variable "redis_aws_ecr_repository" {
  description = "ECR repository URL for the redis service"
  type        = string
  default     = "366140438193.dkr.ecr.ap-south-1.amazonaws.com/redis"
}

variable "redis_tag" {
  description = "Tag for the redis service"
  type        = string
  default     = "latest"
}

variable "redis_container_name" {
  description = "Container name for the redis service"
  type        = string
  default     = "redis"
}
resource "aws_ecr_repository" "python_app" {
  name = var.app_name
}
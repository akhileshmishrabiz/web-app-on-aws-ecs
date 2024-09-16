resource "aws_ecr_repository" "python_app" {
  name = "${var.environment}-${var.app_name}"
}
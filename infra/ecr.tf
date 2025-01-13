resource "aws_ecr_repository" "python_app" {
  name = "${var.environment}-${var.app_name}-flask"
}
resource "aws_ecr_repository" "redis" {
  name = "${var.environment}-${var.app_name}-redis"
}

resource "aws_ecr_repository" "nginx" {
  name = "${var.environment}-${var.app_name}-nginx"
}


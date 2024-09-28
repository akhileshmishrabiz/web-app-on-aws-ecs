resource "aws_ecr_repository" "python_app" {
  name = "${var.environment}-${var.app_name}"
}
# resource "aws_ecr_repository" "redis" {
#   name = "redis"
# }

# resource "aws_ecr_repository" "nginx" {
#   name = "nginx"
# }
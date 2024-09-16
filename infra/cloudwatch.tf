resource "aws_cloudwatch_log_group" "python_app" {
  name = "cloudwatch-log-${var.app_name}-${var.environment}"

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}
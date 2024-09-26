resource "aws_cloudwatch_log_group" "ecs" {
  for_each = { for service in local.ecs_services : service.name => service }

  name              = "/aws/ecs/${var.environment}-${each.value.name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_query_definition" "ecs" {
  for_each = { for service in local.ecs_services : service.name => service }

  name = "${var.environment}-${each.value.name}"

  log_group_names = [
    aws_cloudwatch_log_group.ecs[each.key].name,
  ]

  query_string = <<-EOF
    filter @message not like /.+Waiting.+/
    | fields @timestamp, @message
    | sort @timestamp desc
    | limit 200
  EOF
}
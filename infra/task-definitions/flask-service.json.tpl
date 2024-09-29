[
  {
    "name": "${container_name}",
    "image": "${aws_ecr_repository}:${tag}",
    "essential": true,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "ap-south-1",
        "awslogs-stream-prefix": "${aws_cloudwatch_log_group_name}-service",
        "awslogs-group": "${aws_cloudwatch_log_group_name}"
      }
    },
    "portMappings": [
      {
        "containerPort": 8080,
        "hostPort": 8080,
        "protocol": "tcp",
        "name": "app",
        "appProtocol": "http"
      }
    ],
    "environment": [
      {
        "name": "DB_ADDRESS",
        "value": "${database_address}"
      },
       {
        "name": "DB_NAME",
        "value": "${database_name}"
      },
      {
        "name": "POSTGRES_USERNAME",
        "value": "${postgres_username}"
      },
      {
        "name": "POSTGRES_PASSWORD",
        "value": "${postgres_password}"
      },
      {
        "name": "DATABASE_URL",
        "value": "${database_url}"
      },
      {
        "name": "ENV",
        "value": "${environment}"
      }
    ]
  }
]
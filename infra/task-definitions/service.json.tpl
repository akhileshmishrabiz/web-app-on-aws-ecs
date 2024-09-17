[
  {
    "name": "${container_name}",
    "image": "${aws_ecr_repository}:${tag}",
    "essential": true,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "${aws_cloudwatch_log_group_name}-service",
        "awslogs-group": "${aws_cloudwatch_log_group_name}"
      }
    },
    "portMappings": [
      {
        "containerPort": 5000,
        "hostPort": 5000,
        "protocol": "tcp"
      }
    ],
    "cpu": 1,
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
        "name": "ENV",
        "value": "PROD"
      }
    ],
    "secrets": [{
      "name": "POSTGRES_PASSWORD",
      "valueFrom": "${postgres_password}"
    }],
    "ulimits": [
      {
        "name": "nofile",
        "softLimit": 65536,
        "hardLimit": 65536
      }
    ],
    "mountPoints": [],
    "memory": 2048,
    "volumesFrom": []
  }
]
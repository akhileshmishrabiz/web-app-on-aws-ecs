[
  {
      "name": "nginx",
      "image": "366140438193.dkr.ecr.ap-south-1.amazonaws.com/nginx:latest",
      "memory": 256,
      "cpu": 256,
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "protocol": "tcp"
        }
      ],
      "links": [
        "${container_name}"
      ]
    },
    {
      "name": "redis",
      "image": "redis:latest",
      "memory": 256,
      "cpu": 256,
      "essential": true,
      "portMappings": [
        {
          "containerPort": 6379,
          "hostPort": 6379,
          "protocol": "tcp"
        }
      ],
    },
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
        "name": "POSTGRES_PASSWORD",
        "value": "${postgres_password}"
      },
      {
        "name": "ENV",
        "value": "PROD"
      }
    ],
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
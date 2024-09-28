resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.environment}-vpc"
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, 2 + count.index)
  availability_zone       = data.aws_availability_zones.available_zones.names[count.index]
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true

  tags = {
    Name = "ECS Fargate Public Subnet ${count.index}"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]
  vpc_id            = aws_vpc.main.id

  tags = {
    Name = "ECS Fargate Private Subnet ${count.index}"
  }
}

resource "aws_subnet" "rds" {
  count             = 2
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, 4 + count.index)
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]
  vpc_id            = aws_vpc.main.id

  tags = {
    Name = "RDS Private Subnet ${count.index}"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

# use with private subnet if ecs taska need internet access
# resource "aws_eip" "gateway" {
#   count      = 2
#   depends_on = [aws_internet_gateway.gateway]
# }

# resource "aws_nat_gateway" "gateway" {
#   count         = 2
#   subnet_id     = element(aws_subnet.public.*.id, count.index)
#   allocation_id = element(aws_eip.gateway.*.id, count.index)
# }

# resource "aws_route_table" "private" {
#   count  = 2
#   vpc_id = aws_vpc.main.id
#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = element(aws_nat_gateway.gateway.*.id, count.index)
#   }
#   tags = {
#     Name = "ECS EC2 Private Route Table ${count.index}"
#   }
# }

# resource "aws_route_table_association" "private" {
#   count          = 2
#   subnet_id      = element(aws_subnet.private.*.id, count.index)
#   route_table_id = element(aws_route_table.private.*.id, count.index)
# }

resource "aws_security_group" "lb" {
  name        = "${var.environment}-lb-sg"
  vpc_id      = aws_vpc.main.id
  description = "controls access to the Application Load Balancer (ALB)"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_tasks_flask" {
  name        = "${var.environment}-ecs-tasks-flask-sg"
  vpc_id      = aws_vpc.main.id
  description = "allow inbound access from the ALB only"

  ingress {
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    security_groups = [aws_security_group.ecs_tasks_nginx.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "ecs_tasks_redis" {
  name        = "${var.environment}-ecs-tasks-redis-sg"
  vpc_id      = aws_vpc.main.id
  description = "allow inbound access from the ALB only"

  ingress {
    protocol    = "tcp"
    from_port   = 6379
    to_port     = 6379
    security_groups = [aws_security_group.ecs_tasks_flask.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "ecs_tasks_nginx" {
  name        = "${var.environment}-ecs-tasks-nginx-sg"
  vpc_id      = aws_vpc.main.id
  description = "allow inbound access from the ALB only"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    security_groups = [aws_security_group.lb.id]

  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

}
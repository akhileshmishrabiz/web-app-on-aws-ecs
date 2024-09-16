# web-app-on-aws
Flask with RDS on aws EC2 behind A load balancer


# ecs public module
# https://github.com/terraform-aws-modules/terraform-aws-ecs

# https://github.com/MatthewCYLau/python-flask-aws-terraform/blob/master/deploy/13-rds.tf



# run terraform 

terraform init -backend-config=dev.tfbackend

terraform plan -var-file=dev.tfvars

terraform apply -var-file=dev.tfvars

# On prod 

terraform init -backend-config=prod.tfbackend

terraform plan -var-file=prod.tfvars

terraform apply -var-file=prod.tfvars


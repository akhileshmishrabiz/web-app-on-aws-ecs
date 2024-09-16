# web-app-on-aws
Flask with RDS on aws EC2 behind A load balancer


# ecs public module
# https://github.com/terraform-aws-modules/terraform-aws-ecs

# https://github.com/MatthewCYLau/python-flask-aws-terraform/blob/master/deploy/13-rds.tf



# run terraform 

terraform init -backend-config=vars/dev.tfbackend

terraform plan -var-file=vars/dev.tfvars

terraform apply -var-file=vars/dev.tfvars

# On prod 

terraform init -backend-config=vars/prod.tfbackend

terraform plan -var-file=vars/prod.tfvars

terraform apply -var-file=vars/prod.tfvars


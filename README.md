# To run locally, run with postgres container
cd /app

docker run --name flask_postgres -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=password -e POSTGRES_DB=postgres -p 5432:5432 -d postgres

docker run --name flask_redis -p 6379:6379 -d redis

python app.py

# run app with dockr-compose

cd app

docker-compose up --build



# To deploy in aws account

1. Create all the ecr repositories

2. Build the redis, nginx and app images

3. login to ecr

4. push images to their respective repos

# ecr login 

aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 366140438193.dkr.ecr.ap-south-1.amazonaws.com


# app image build 

cd app

docker build --platform linux/amd64 -t <repo URI>:<tag> .

docker push <repo URI>:<tag>


# nginx image build 

cd app/nginx

docker build --platform linux/amd64 -t <repo URI>:<tag> .

docker push <repo URI>:<tag>


# redis image build 
cd app/redis

docker build --platform linux/amd64 -t <repo URI>:<tag> .

docker push <repo URI>:<tag>

### Deploy the rest of infra  ###

# run terraform 

terraform init -backend-config=vars/dev.tfbackend

terraform plan -var-file=vars/dev.tfvars

terraform apply -var-file=vars/dev.tfvars

# On prod 

terraform init -backend-config=vars/prod.tfbackend

terraform plan -var-file=vars/prod.tfvars

terraform apply -var-file=vars/prod.tfvars


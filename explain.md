-> 
we have 1 flask app -> gvicorn  
nginx -> this willl serve static files
with flask we can use -> celery -> background work -> Redis 

-> Redis -> its a on memory database -> used for cache purpose 




what will nginx do
- Reverse proxy -> when we access the app, we will not know the servers, we ill only know nginx
- load balancing
- caching 



To run apps as docker on aws 
-> ECS -> this use case
-> EKS 


this 3 container app 
how you want to run it
-> all contaners in on service
-> all in different services

we choose 3 services for each of them
1. ecs service for nginx -> 80
2. ecs service for flask -> 8080
3. ecs service for redis -> 6379

1 vpc -> 
 private subnets for ecs -> here your  services will be running
 nat gateway/ vpc endpoint for ecs private subnets -> 
 public subnet -> here your load balancer will run
 private rds subnet -> here your postgres will ve running

 security group:
    ecs_nginx_sg: inbound on 80 port -> from ALB ALB_sg
    ecs_flask_sg: inbound on 8080 port -> from  ecs_nginx_sg
    ecs_redis_sg: inbound on port 6379 -> from  cs_flask_sg
    ALB_sg: inbound on http or https (80 or 443) -> public
    rds_sg: inbound on port 5432 - from ecs_flask_sg

ECS:
    ECS cluster:
        ECS_Service_nginx: will use a task def to define how to run the app
        ECS_Service_flask: will use a task def to define how to run the app
        ECS_Service_redis: will use a task def to define how to run the app

RDS:
    postgres db:
        rds instance: for dev
        rds_cluster: for prod


RDS -> rds instance: 
            single rds db:
            db with a standby db:
            db with a read replica:

        rds_arora_cluster:
            different reader:
            different writer

            
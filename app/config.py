import os

db_host = os.environ.get("DB_ADDRESS") 
db_name = os.environ.get("DB_NAME")
db_port = "5432"
postgres_username = os.environ.get("POSTGRES_USERNAME")
postgres_password = os.environ.get("POSTGRES_PASSWORD")

class Config:

    # Uncomment when running on prod
    SQLALCHEMY_DATABASE_URI = SQLALCHEMY_DATABASE_URI =  f'postgresql://{postgres_username}:{postgres_password}@{db_host}:{db_port}/{db_name}'
    #### SQLALCHEMY_DATABASE_URI = 'postgresql://postgres:tyVs6cQBoz@dev-app-db.cfykukwcw419.ap-south-1.rds.amazonaws.com:5432/mydb'

    SQLALCHEMY_TRACK_MODIFICATIONS = False
    CELERY_BROKER_URL = 'redis://redis:6379/0'
    CELERY_RESULT_BACKEND = 'redis://redis:6379/0'

     # with docker-compose
     # comment out when running with docker compose
    # SQLALCHEMY_DATABASE_URI = 'postgresql://postgres:password@db:5432/mydb' 

    

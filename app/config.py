import os

db_host = os.environ.get("DB_ADDRESS") 
db_name = os.environ.get("DB_NAME")
db_port = "5432"
postgres_username = os.environ.get("POSTGRES_USERNAME")
postgres_password = os.environ.get("POSTGRES_PASSWORD")

class Config:
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL', f'postgresql://{postgres_username}:{postgres_password}@{db_host}:{db_port}/{db_name}')
    # SQLALCHEMY_DATABASE_URI = 'postgresql://postgres:tyVs6cQBoz@dev-web-app-db.cfykukwcw419.ap-south-1.rds.amazonaws.com:5432/mydb'
    # SQLALCHEMY_DATABASE_URI = 'postgresql://postgres:password@db:5432/mydb'   # with docker-compose

    SQLALCHEMY_TRACK_MODIFICATIONS = False
    CELERY_BROKER_URL = 'redis://redis:6379/0'
    CELERY_RESULT_BACKEND = 'redis://redis:6379/0'

    # while running locally
    # CELERY_BROKER_URL = 'redis://localhost:6379/0'
    # CELERY_RESULT_BACKEND = 'redis://localhost:6379/0'
    # SQLALCHEMY_DATABASE_URI = 'postgresql://postgres:password@localhost:5432/postgres'   # running locally

    

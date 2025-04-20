import os

db_host = os.environ.get("DB_ADDRESS") 
db_name = os.environ.get("DB_NAME")
db_port = "5432"
postgres_username = os.environ.get("POSTGRES_USERNAME")
postgres_password = os.environ.get("POSTGRES_PASSWORD")

class Config:

    SQLALCHEMY_DATABASE_URI = SQLALCHEMY_DATABASE_URI =  f'postgresql://{postgres_username}:{postgres_password}@{db_host}:{db_port}/{db_name}'
    
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    CELERY_BROKER_URL = 'redis://redis:6379/0'
    CELERY_RESULT_BACKEND = 'redis://redis:6379/0'

  

    

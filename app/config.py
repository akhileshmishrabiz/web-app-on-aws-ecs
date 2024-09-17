import os

db_host = os.environ.get("DB_ADDRESS", "db") 
db_name = os.environ.get("DB_NAME", "mydb")
db_port = "5432"
postgres_username = os.environ.get("POSTGRES_USERNAME", "postgres")
postgres_password = os.environ.get("POSTGRES_PASSWORD", "password")

class Config:
    # SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL', f'postgresql://{postgres_username}:{postgres_password}@{db_host}:{db_port}/{db_name}')
    SQLALCHEMY_DATABASE_URI = 'postgresql://postgres:password@db:5432/mydb'
    SQLALCHEMY_TRACK_MODIFICATIONS = False


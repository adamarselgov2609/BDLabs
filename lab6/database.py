from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

DB_USER = "amin"
DB_PASSWORD = ""        
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "postgres"

DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

engine = create_engine(
    DATABASE_URL,
    connect_args={
        "client_encoding": "utf8",
        "options": "-c client_encoding=UTF8"
    }
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
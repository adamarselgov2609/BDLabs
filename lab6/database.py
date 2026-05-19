# database.py
# Настройка подключения к PostgreSQL и сессий SQLAlchemy

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# =========================================================
# НАСТРОЙКИ БД
# =========================================================

DB_USER = "amin"
DB_PASSWORD = ""  # у тебя пароль не используется
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "postgres"

# =========================================================
# DATABASE URL
# =========================================================

# Если пароль пустой — убираем ":password"
if DB_PASSWORD:
    DATABASE_URL = (
        f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}"
        f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )
else:
    DATABASE_URL = (
        f"postgresql+psycopg2://{DB_USER}"
        f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )

# =========================================================
# ENGINE
# =========================================================

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,  # защита от "мертвых" соединений
)

# =========================================================
# SESSION
# =========================================================

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

# =========================================================
# BASE (ЕДИНЫЙ ДЛЯ ВСЕХ МОДЕЛЕЙ)
# =========================================================

Base = declarative_base()


# =========================================================
# DEPENDENCY (ОПЦИОНАЛЬНО, НО ОЧЕНЬ ПОЛЕЗНО)
# =========================================================

def get_db():
    """
    Dependency для FastAPI:
    автоматически создаёт и закрывает сессию БД
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
"""
Database configuration and session management
"""

from sqlalchemy.orm.session import Session
import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

DATABASE_USER = os.getenv("DATABASE_USER", "postgres")
DATABASE_PASSWORD = os.getenv("DATABASE_PASSWORD", "postgres")
DATABASE_HOST = os.getenv("DATABASE_HOST", "localhost")
DATABASE_PORT = os.getenv("DATABASE_PORT", "5432")
DATABASE_NAME = os.getenv("DATABASE_NAME", "university_registration")

SQLALCHEMY_DATABASE_URL = (
    f"postgresql://{DATABASE_USER}:{DATABASE_PASSWORD}@"
    f"{DATABASE_HOST}:{DATABASE_PORT}/{DATABASE_NAME}"
)

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    pool_pre_ping=True,  # Verify connections before using them
    pool_size=1,
    max_overflow=0,
    isolation_level = "AUTOCOMMIT"
    # isolation_level="SERIALIZABLE"
)
SessionLocal = sessionmaker[Session](autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()
#backend/models.py
from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from database import Base
from pydantic import BaseModel
from typing import Optional

# ==================== MODÈLES SQLAlchemy ====================

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    
    # Relation avec les contacts
    persons = relationship("Person", back_populates="owner", cascade="all, delete-orphan")


class Person(Base):
    __tablename__ = "persons"
    
    id = Column(Integer, primary_key=True, index=True)
    nom = Column(String, index=True)
    prenom = Column(String, index=True)
    telephone = Column(String, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    
    # Relation avec l'utilisateur
    owner = relationship("User", back_populates="persons")


# ==================== MODÈLES Pydantic ====================

# User Schemas
class UserCreate(BaseModel):
    username: str
    email: str
    password: str


class UserLogin(BaseModel):
    username: str
    password: str


class UserResponse(BaseModel):
    id: int
    username: str
    email: str
    
    class Config:
        from_attributes = True


# Person Schemas
class PersonCreate(BaseModel):
    nom: str
    prenom: str
    telephone: str


class PersonUpdate(BaseModel):
    nom: Optional[str] = None
    prenom: Optional[str] = None
    telephone: Optional[str] = None


class PersonResponse(BaseModel):
    id: int
    nom: str
    prenom: str
    telephone: str
    user_id: int
    
    class Config:
        from_attributes = True


# Token Schema
class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse
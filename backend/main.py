#backend/main.py
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List
from database import engine, get_db
from models import Base, User, Person
from models import UserCreate, UserLogin, UserResponse, Token
from models import PersonCreate, PersonUpdate, PersonResponse
from auth import get_password_hash, verify_password, create_access_token, get_current_user

# Créer les tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Contact Management API")

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ==================== ROUTES D'AUTHENTIFICATION ====================

@app.post("/auth/register", response_model=Token, status_code=status.HTTP_201_CREATED)
def register(user: UserCreate, db: Session = Depends(get_db)):
    """Inscription d'un nouvel utilisateur"""
    
    # Vérifier si le username existe déjà
    if db.query(User).filter(User.username == user.username).first():
        raise HTTPException(
            status_code=400,
            detail="Ce nom d'utilisateur existe déjà"
        )
    
    # Vérifier si l'email existe déjà
    if db.query(User).filter(User.email == user.email).first():
        raise HTTPException(
            status_code=400,
            detail="Cet email existe déjà"
        )
    
    # Créer le nouvel utilisateur
    hashed_password = get_password_hash(user.password)
    db_user = User(
        username=user.username,
        email=user.email,
        hashed_password=hashed_password
    )
    
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    # Créer le token
    access_token = create_access_token(data={"sub": db_user.id})
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": db_user
    }


@app.post("/auth/login", response_model=Token)
def login(user: UserLogin, db: Session = Depends(get_db)):
    """Connexion d'un utilisateur"""
    
    # Chercher l'utilisateur
    db_user = db.query(User).filter(User.username == user.username).first()
    
    if not db_user or not verify_password(user.password, db_user.hashed_password):
        raise HTTPException(
            status_code=401,
            detail="Nom d'utilisateur ou mot de passe incorrect"
        )
    
    # Créer le token
    access_token = create_access_token(data={"sub": db_user.id})
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": db_user
    }


@app.get("/auth/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    """Récupère les informations de l'utilisateur connecté"""
    return current_user


# ==================== ROUTES DES CONTACTS ====================

@app.post("/personnes", response_model=PersonResponse, status_code=status.HTTP_201_CREATED)
def create_person(
    person: PersonCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Ajouter un nouveau contact"""
    
    # Vérifier si le téléphone existe déjà pour cet utilisateur
    existing = db.query(Person).filter(
        Person.telephone == person.telephone,
        Person.user_id == current_user.id
    ).first()
    
    if existing:
        raise HTTPException(
            status_code=400,
            detail="Ce numéro de téléphone existe déjà dans vos contacts"
        )
    
    # Créer le contact
    db_person = Person(
        nom=person.nom,
        prenom=person.prenom,
        telephone=person.telephone,
        user_id=current_user.id
    )
    
    db.add(db_person)
    db.commit()
    db.refresh(db_person)
    
    return db_person


@app.get("/personnes", response_model=List[PersonResponse])
def get_persons(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Récupérer tous les contacts de l'utilisateur"""
    persons = db.query(Person).filter(Person.user_id == current_user.id).all()
    return persons


@app.get("/personnes/{person_id}", response_model=PersonResponse)
def get_person(
    person_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Récupérer un contact spécifique"""
    person = db.query(Person).filter(
        Person.id == person_id,
        Person.user_id == current_user.id
    ).first()
    
    if not person:
        raise HTTPException(status_code=404, detail="Contact non trouvé")
    
    return person


@app.put("/personnes/{person_id}", response_model=PersonResponse)
def update_person(
    person_id: int,
    person_update: PersonUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Modifier un contact"""
    
    # Chercher le contact
    person = db.query(Person).filter(
        Person.id == person_id,
        Person.user_id == current_user.id
    ).first()
    
    if not person:
        raise HTTPException(status_code=404, detail="Contact non trouvé")
    
    # Vérifier si le nouveau téléphone existe déjà
    if person_update.telephone:
        existing = db.query(Person).filter(
            Person.telephone == person_update.telephone,
            Person.user_id == current_user.id,
            Person.id != person_id
        ).first()
        
        if existing:
            raise HTTPException(
                status_code=400,
                detail="Ce numéro de téléphone existe déjà"
            )
    
    # Mettre à jour les champs
    if person_update.nom is not None:
        person.nom = person_update.nom
    if person_update.prenom is not None:
        person.prenom = person_update.prenom
    if person_update.telephone is not None:
        person.telephone = person_update.telephone
    
    db.commit()
    db.refresh(person)
    
    return person


@app.delete("/personnes/{person_id}")
def delete_person(
    person_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Supprimer un contact"""
    
    person = db.query(Person).filter(
        Person.id == person_id,
        Person.user_id == current_user.id
    ).first()
    
    if not person:
        raise HTTPException(status_code=404, detail="Contact non trouvé")
    
    db.delete(person)
    db.commit()
    
    return {"message": "Contact supprimé avec succès"}


# ==================== ROUTE DE TEST ====================

@app.get("/")
def root():
    return {
        "message": "API de Gestion de Contacts",
        "version": "1.0.0",
        "endpoints": {
            "auth": ["/auth/register", "/auth/login", "/auth/me"],
            "contacts": ["/personnes"]
        }
    }


if __name__ == "__main__":
    import uvicorn
    # host="0.0.0.0" permet l'accès depuis d'autres appareils
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
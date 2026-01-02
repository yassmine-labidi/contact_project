from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from database import get_db
from models import User

# Configuration
SECRET_KEY = "votre_cle_secrete_super_longue_et_complexe_12345"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 1440  # 24 heures

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
security = HTTPBearer()


def verify_password(plain_password, hashed_password):
    """Vérifie si le mot de passe est correct"""
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password):
    """Hash le mot de passe"""
    return pwd_context.hash(password)


def create_access_token(data: dict):
    """Crée un token JWT"""
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    
    # Convertir sub en string si c'est un int
    if "sub" in to_encode and isinstance(to_encode["sub"], int):
        to_encode["sub"] = str(to_encode["sub"])
    
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    print(f"✅ Token créé pour user_id: {data.get('sub')}")
    return encoded_jwt


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
):
    """Récupère l'utilisateur connecté depuis le token"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Non autorisé. Veuillez vous reconnecter.",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        token = credentials.credentials
        print(f"🔍 Token reçu: {token[:30]}...")
        
        # Décoder le token
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        print(f"📦 Payload décodé: {payload}")
        
        # Récupérer sub et le convertir en int
        user_id_str = payload.get("sub")
        if user_id_str is None:
            print("❌ user_id est None dans le payload")
            raise credentials_exception
        
        # Convertir en int
        try:
            user_id = int(user_id_str)
            print(f"✅ User ID: {user_id}")
        except ValueError:
            print(f"❌ Impossible de convertir '{user_id_str}' en int")
            raise credentials_exception
        
    except JWTError as e:
        print(f"❌ Erreur JWT: {e}")
        raise credentials_exception
    except Exception as e:
        print(f"❌ Erreur inattendue: {e}")
        raise credentials_exception
    
    # Chercher l'utilisateur dans la base de données
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        print(f"❌ Utilisateur non trouvé avec id: {user_id}")
        raise credentials_exception
    
    print(f"✅ Utilisateur authentifié: {user.username}")
    return user
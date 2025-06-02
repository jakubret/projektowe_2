from flask import Flask, request, jsonify, send_from_directory # Importujemy send_from_directory
import tensorflow as tf
import numpy as np
import os
import cv2
from werkzeug.utils import secure_filename
from flask_cors import CORS
import google.generativeai as genai
from sqlalchemy import create_engine, Column, Integer, String, Text, ForeignKey
from sqlalchemy.orm import declarative_base, sessionmaker, relationship
from keras.utils import custom_object_scope
from keras.layers import Layer
from werkzeug.security import check_password_hash, generate_password_hash
from flask_socketio import SocketIO, emit, join_room, leave_room
from flask import session
import re

# Import for Swagger UI
from flask_swagger_ui import get_swaggerui_blueprint

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = 'uploads/'
app.config['SECRET_KEY'] = 'your_secret_key'
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*", async_mode="eventlet")


SWAGGER_URL = '/swagger'  #
API_SPEC_DIR = './' 
API_URL = '/swagger.yaml' 

@app.route(API_URL)
def serve_swagger_yaml():
    return send_from_directory(API_SPEC_DIR, 'swagger.yaml')

swaggerui_blueprint = get_swaggerui_blueprint(
    SWAGGER_URL,
    API_URL, 
    config={
        'app_name': "Monument Recognition API"
    }
)
app.register_blueprint(swaggerui_blueprint, url_prefix=SWAGGER_URL)


GEMINI_API_KEY = "-"
genai.configure(api_key=GEMINI_API_KEY)
model_gemini = genai.GenerativeModel("gemini-2.0-flash")

DB_USER = "-"
DB_PASS = "-"
DB_NAME = "-"
DB_HOST = "-"
DB_PORT = "-"

engine = create_engine(f'postgresql+psycopg2://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}')
Base = declarative_base()

class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True)
    name = Column(String(255), nullable=False)
    email = Column(String(255), unique=True, nullable=False)
    password = Column(String(255), nullable=False)
    queries = relationship("Zapytanie", back_populates="user")

class NearbyMonument(Base):
    __tablename__ = 'nearby_monuments'
    id = Column(Integer, primary_key=True)
    query_id = Column(Integer, ForeignKey('zapytania.id'))
    main_monument = Column(String(255), nullable=False)
    nearby_monument = Column(String(255), nullable=False)

class Zapytanie(Base):
    __tablename__ = 'zapytania'
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    zabytek = Column(String(255))
    question = Column(Text)
    answer = Column(Text)
    user = relationship("User", back_populates="queries")
    nearby_monuments = relationship("NearbyMonument", backref="query", cascade="all, delete-orphan")

Base.metadata.create_all(engine)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

class CastLayer(Layer):
    def call(self, inputs):
        return tf.cast(inputs, tf.float16)

with custom_object_scope({"Cast": CastLayer}):
    try:
        model = tf.keras.models.load_model("zabytki_model3.h5")
    except Exception as e:
        print(f"Error loading model: {e}")
        model = None

train_dir = "dataset2/"
if os.path.exists(train_dir):
    class_labels = sorted([d for d in os.listdir(train_dir) if os.path.isdir(os.path.join(train_dir, d))])
else:
    print(f"Warning: '{train_dir}' directory not found. Prediction endpoint might not work as expected.")
    class_labels = []

# --- Sztuczna mapa zabytków w okolicy ---
nearby_monuments_map = {
    "Wawel": ["Smocza Jama", "Katedra Wawelska"],
    "Koloseum": ["Forum Romanum", "Łuk Konstantyna"],
    "eiffel_tower": ["Sekwana", "Trocadéro"]
}

def get_gemini_description(zabytek):
    prompt = f"Opowiedz ciekawostki na temat zabytku {zabytek}. Podaj krótką i interesującą odpowiedź."
    try:
        response = model_gemini.generate_content(prompt)
        return response.text if response else "Brak informacji."
    except Exception as e:
        print(f"Error calling Gemini API for description: {e}")
        return "Wystąpił problem z pobraniem informacji. Spróbuj ponownie później."

@app.route('/predict/', methods=['POST'], strict_slashes=False)
def predict():
    if model is None:
        return jsonify({'error': 'Model ładowania zabytków nie jest dostępny.'}), 500

    if 'file' not in request.files:
        return jsonify({'error': 'No file uploaded'}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    filename = secure_filename(file.filename)
    filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
    file.save(filepath)

    try:
        img = cv2.imread(filepath)
        if img is None:
            return jsonify({'error': 'Could not read image file'}), 400

        img = cv2.resize(img, (224, 224))
        img = img / 255.0
        img = np.expand_dims(img, axis=0)

        prediction = model.predict(img)
        if not class_labels:
            return jsonify({'error': 'Brak etykiet klas do predykcji. Sprawdź konfigurację katalogu dataset2.'}), 500

        predicted_class = class_labels[np.argmax(prediction)]

        description = get_gemini_description(predicted_class)

        return jsonify({'prediction': predicted_class, 'description': description})
    except Exception as e:
        print(f"Error during prediction: {e}")
        return jsonify({'error': f'Wystąpił błąd podczas przetwarzania obrazu: {e}'}), 500
    finally:
        if os.path.exists(filepath):
            os.remove(filepath)

def extract_nearby_monuments(answer):
    matches = re.findall(r'([A-Z][a-zA-Z\s]+(?:(?:, and| and|,|;|\s)?[A-Z][a-zA-Z\s]+)*)', answer)
    monuments = []
    for match in matches:
        parts = re.split(r',\s*| and |\s*i\s*|\s*oraz\s*|\.\s*', match)
        for p in parts:
            cleaned_p = p.strip(" .")
            if len(cleaned_p) > 2 and \
               cleaned_p.lower() not in ["w okolicy", "znajdują się", "można zobaczyć", "to", "w pobliżu",
                                          "oraz", "jest", "a także", "także"]:
                monuments.append(cleaned_p)
    return list(set(monuments))

@app.route('/ask/', methods=['POST'])
def ask_question():
    data = request.json
    zabytek = data.get("zabytek")
    question = data.get("question")
    user_id = data.get("user_id")
    max_tokens_for_nearby = 200
    max_tokens_default = data.get("max_tokens", 250)

    if not zabytek or not question or not user_id:
        return jsonify({"error": "Brak zabytku, pytania lub ID użytkownika"}), 400

    db = SessionLocal()
    try:
        if "zabytki w okolicy" in question.lower() or "w pobliżu" in question.lower():
            monuments = nearby_monuments_map.get(zabytek, []).copy()

            if len(monuments) < 5 or "wszystkie zabytki w okolicy" in question.lower():
                prompt = f"Wypisz listę do 5 znanych zabytków znajdujących się w bezpośrednim sąsiedztwie {zabytek}. Użyj formatu: '1. [Zabytek A], 2. [Zabytek B], 3. [Zabytek C], ...' lub po prostu oddziel je przecinkami."
                try:
                    response = model_gemini.generate_content(prompt, generation_config={"max_output_tokens": max_tokens_for_nearby})
                    gemini_monuments_text = response.text if response else ""
                except Exception as e:
                    print(f"Error calling Gemini API for nearby monuments: {e}")
                    gemini_monuments_text = ""

                gemini_extracted_monuments = extract_nearby_monuments(gemini_monuments_text)

                current_monuments_set = set(monuments)
                for gm in gemini_extracted_monuments:
                    if len(current_monuments_set) < 5 and gm not in current_monuments_set:
                        current_monuments_set.add(gm)

                monuments = list(current_monuments_set)[:5]

            if monuments:
                answer_text = f"W okolicy zabytku {zabytek} możesz również zobaczyć: " + ", ".join(monuments) + "."
            else:
                answer_text = f"Nie posiadam informacji o innych zabytkach w okolicy {zabytek}."

            new_query = Zapytanie(user_id=user_id, zabytek=zabytek, question=question, answer=answer_text)
            db.add(new_query)
            db.commit()
            db.refresh(new_query)

            for monument in monuments:
                nearby_entry = NearbyMonument(query_id=new_query.id, main_monument=zabytek, nearby_monument=monument)
                db.add(nearby_entry)
            db.commit()

            socketio.emit('new_query', {
                "id": new_query.id,
                "zabytek": new_query.zabytek,
                "question": new_query.question,
                "answer": new_query.answer,
                "user_id": new_query.user_id,
                "nearby_monuments": monuments
            }, room=f'user_{user_id}', namespace='/')

            return jsonify({"answer": answer_text, "nearby_monuments": monuments})

        # --- Standardowe pytania ---
        context = f"Odpowiadaj na pytania dotyczące zabytku: {zabytek}. Jeśli pytanie nie dotyczy bezpośrednio tego zabytku, odpowiedz: 'To pytanie nie dotyczy tego zabytku.'"
        prompt = f"{context}\nPytanie użytkownika: {question}"

        try:
            response = model_gemini.generate_content(prompt, generation_config={"max_output_tokens": max_tokens_default})
            answer_text = response.text if response else "Brak odpowiedzi."
        except Exception as e:
            print(f"Error calling Gemini API for standard question: {e}")
            answer_text = "Wystąpił problem z uzyskaniem odpowiedzi. Spróbuj ponownie później."


        new_query = Zapytanie(user_id=user_id, zabytek=zabytek, question=question, answer=answer_text)
        db.add(new_query)
        db.commit()
        db.refresh(new_query)

        socketio.emit('new_query', {
            "id": new_query.id,
            "zabytek": new_query.zabytek,
            "question": new_query.question,
            "answer": new_query.answer,
            "user_id": new_query.user_id
        }, room=f'user_{user_id}', namespace='/')

        return jsonify({"answer": answer_text})
    finally:
        db.close()

@app.route('/register', methods=['POST'])
def register():
    data = request.json
    name = data.get('name')
    email = data.get('email')
    password = data.get('password')

    if not name or not email or not password:
        return jsonify({'error': 'Brak wymaganych danych'}), 400

    hashed_password = generate_password_hash(password)

    db = SessionLocal()
    try:
        existing_user = db.query(User).filter(User.email == email).first()
        if existing_user:
            return jsonify({'error': 'Użytkownik o tym emailu już istnieje'}), 409

        new_user = User(name=name, email=email, password=hashed_password)
        db.add(new_user)
        db.commit()
        return jsonify({'message': 'Rejestracja udana'}), 201
    except Exception as e:
        print(f"Error during registration: {e}")
        db.rollback()
        return jsonify({'error': f'Wystąpił błąd podczas rejestracji: {e}'}), 500
    finally:
        db.close()

@app.route('/history', methods=['GET'])
def get_history():
    user_id = request.args.get('user_id')

    if not user_id:
        return jsonify({"error": "Brak ID użytkownika"}), 400

    db = SessionLocal()
    try:
        history = db.query(Zapytanie).filter(Zapytanie.user_id == user_id).order_by(Zapytanie.id.desc()).all()
        history_list = [{"id": h.id, "zabytek": h.zabytek, "question": h.question, "answer": h.answer} for h in history]
        return jsonify(history_list)
    except Exception as e:
        print(f"Error fetching history: {e}")
        return jsonify({'error': f'Wystąpił błąd podczas pobierania historii: {e}'}), 500
    finally:
        db.close()

@app.route('/login', methods=['POST'])
def login():
    data = request.json
    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({'error': 'Brak emaila lub hasła'}), 400

    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == email).first()
        if user and check_password_hash(user.password, password):
            return jsonify({'message': 'Logowanie udane', 'user': {'id': user.id, 'name': user.name, 'email': user.email}}), 200
        else:
            return jsonify({'error': 'Nieprawidłowe hasło lub email'}), 401
    except Exception as e:
        print(f"Error during login: {e}")
        return jsonify({'error': f'Wystąpił błąd podczas logowania: {e}'}), 500
    finally:
        db.close()

@socketio.on('connect')
def handle_connect():
    user_id = request.args.get('user_id')
    if user_id:
        session['user_id'] = user_id
        join_room(f'user_{user_id}')
        print(f"Użytkownik {user_id} połączył się.")
    else:
        print("Użytkownik połączył się bez user_id.")

@socketio.on('disconnect')
def handle_disconnect():
    user_id = session.get('user_id')
    if user_id:
        leave_room(f'user_{user_id}')
        print(f"Użytkownik {user_id} rozłączył się.")
    else:
        print("Użytkownik rozłączył się (brak user_id w sesji).")

if __name__ == '__main__':
    socketio.run(app, debug=True, host="0.0.0.0", port=8000)
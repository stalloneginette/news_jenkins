# Sur votre machine locale
echo 'FROM python:3.9-slim

WORKDIR /app
COPY app/ /app/
RUN pip install fastapi uvicorn pytest

EXPOSE 80

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]' > Dockerfile

# Créez un fichier FastAPI simple
echo 'from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"Hello": "World"}' > app/main.py

# Ajoutez-les à git et poussez
git add Dockerfile app/main.py
git commit -m "Ajouter Dockerfile et application FastAPI simple"
git push

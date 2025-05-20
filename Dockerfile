FROM python:3.9-slim

WORKDIR /app
COPY app/ /app/
RUN pip install fastapi uvicorn pytest

EXPOSE 80

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]

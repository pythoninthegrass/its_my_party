# syntax=docker/dockerfile:1.6

FROM python:3.11-slim-buster

WORKDIR /app

ADD . .

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8000

CMD ["gunicorn", "-b", "0.0.0.0:8000", "app:app"]

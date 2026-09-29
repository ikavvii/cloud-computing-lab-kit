FROM python:3.12-slim-bookworm
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && useradd -m lab
COPY app.py schema.sql test_app.py ./
COPY templates ./templates
USER lab
ENV PORT=8000
CMD ["sh", "-c", "exec gunicorn --bind 0.0.0.0:${PORT:-8000} --workers 1 --access-logfile - app:app"]

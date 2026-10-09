FROM python:3.11-slim

WORKDIR /app

# Install ffmpeg for media processing and clean apt cache to keep image small
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

# Copy all project files (main.py and any helpers)
COPY . .

# Expose standard default port (mostly for documentation)
EXPOSE 8000

# Use shell form with ${PORT:-8000} so it binds to the host's assigned port in cloud, or 8000 locally
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}"]
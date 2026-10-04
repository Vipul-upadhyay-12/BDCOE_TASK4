# 1. Start with a standard Python environment
FROM python:3.11-slim

# 2. Set the working directory inside the container
WORKDIR /app

# 3. Install ffmpeg (for audio) and tesseract-ocr (for reading slides)
RUN apt-get update && apt-get install -y ffmpeg tesseract-ocr

# 4. Copy your requirements and install them
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 5. Copy your actual code into the container
COPY main.py .

# 6. Open port 8000
EXPOSE 8000

# 7. Command to start the server
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
# 1. Start with a standard Python environment
FROM python:3.11-slim

# 2. Set the working directory inside the container
WORKDIR /app

# 3. Copy your requirements and install them
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. Copy your actual code into the container
COPY main.py .

# 5. Open port 8000 so the outside world can connect
EXPOSE 8000

# 6. Command to start the server when the container launches
# Notice we use 0.0.0.0 here so it accepts connections from outside the container
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
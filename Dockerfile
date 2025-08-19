FROM python:3.10-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5000
RUN ls -l /app
RUN cat /app/app.py || echo "app.py not found"
CMD ["python", "app.py"]

FROM python:3.11-slim
WORKDIR /app
# Copy requirements.txt dari folder app
COPY app/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
# Copy seluruh folder app ke /app/app
COPY app /app/app
# Copy model ML (.tflite) ke /app/ya/assets
COPY ya/assets /app/ya/assets
# Run uvicorn dengan module path yang benar
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

# Use Python 3.12 as specified
FROM python:3.12.9-slim

# Set working directory
WORKDIR /app

# Create output directory for models
RUN mkdir -p output

# Install curl
RUN apt-get update && apt-get install -y curl

# Download the model (will be overwritten if the model is mounted)
RUN curl -L -o /app/output/model.joblib \
        https://github.com/doda25-team9/model-service/releases/download/v0.2.0/model.joblib

# Download the preprocessor (will be overwritten if the model is mounted)
RUN curl -L -o /app/output/preprocessor.joblib \
        https://github.com/doda25-team9/model-service/releases/download/v0.2.0/preprocessor.joblib

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt
RUN python -m nltk.downloader stopwords

# Copy source code and data
COPY src/ ./src/
COPY smsspamcollection/ ./smsspamcollection/

ENV MODEL_PORT=8081

# Expose port 8081
EXPOSE 8081

# Run the model service
CMD ["python", "src/serve_model.py"]
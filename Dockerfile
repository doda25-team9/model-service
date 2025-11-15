# Use Python 3.12 as specified
FROM python:3.12.9-slim

# Set working directory
WORKDIR /app

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code and data
COPY src/ ./src/
COPY smsspamcollection/ ./smsspamcollection/

# Create output directory for models
RUN mkdir -p output

# Expose port 8081
EXPOSE 8081

# Run the model service
CMD ["python", "src/serve_model.py"]
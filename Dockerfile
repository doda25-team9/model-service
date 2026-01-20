# STAGE 1: Builds
# Use Python 3.12 as specified
FROM python:3.12.9-slim AS builder

# Set working directory
WORKDIR /app

# Install compilation tools (gcc) needed for some ML libraries
# We do this here so they don't end up in the final image
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Install dependencies into a localized folder (/install)
# Copy requirements file
COPY requirements.txt .
RUN pip install --prefix=/install -r requirements.txt

# STAGE 2: The Runtime
FROM python:3.12.9-slim

WORKDIR /app

# Install curl AND ca-certificates for HTTPS
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy installed python libraries from Stage 1
COPY --from=builder /install /usr/local

# Copy Source Code
COPY src/ src/
COPY smsspamcollection/ smsspamcollection/

# Copy the smart startup script & make it executable
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

# Create output directory
RUN mkdir -p /app/output

ENV MODEL_PORT=8081

# Expose port 8081
EXPOSE 8081

# Use the script as the entrypoint
ENTRYPOINT ["./entrypoint.sh"]

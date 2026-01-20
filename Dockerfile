# STAGE 1: Builds
FROM python:3.12.9-slim AS builder

WORKDIR /app

# Install compilation tools
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Install dependencies
COPY requirements.txt .
RUN pip install --prefix=/install -r requirements.txt

# STAGE 2: Runtime
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

# Copy entrypoint script
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

# Create output directory
RUN mkdir -p /app/output

ENV MODEL_PORT=8081

EXPOSE 8081

ENTRYPOINT ["./entrypoint.sh"]
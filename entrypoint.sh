#!/bin/sh
set -e

# Configuration
MODEL_DIR="${MODEL_DIR:-/app/output}"
MODEL_VERSION="${MODEL_VERSION:-v0.1.0}"
MODEL_FILE="${MODEL_DIR}/model.joblib"
PREPROCESSOR_FILE="${MODEL_DIR}/preprocessor.joblib"
DOWNLOAD_URL_BASE="https://github.com/doda25-team9/model-service/releases/download/${MODEL_VERSION}"

echo "Starting Model Service..."
echo "Model directory: ${MODEL_DIR}"
echo "Model version: ${MODEL_VERSION}"

# Check if both models exist
if [ -f "$MODEL_FILE" ] && [ -f "$PREPROCESSOR_FILE" ]; then
    echo "Models found in volume. Skipping download."
else
    echo "Models not found in volume. Downloading..."
    
    # Ensure directory exists
    mkdir -p "$MODEL_DIR"
    
    # Download model
    echo "Downloading model.joblib..."
    if ! curl -L -o "$MODEL_FILE" "${DOWNLOAD_URL_BASE}/model.joblib"; then
        echo "Failed to download model.joblib"
        exit 1
    fi
    
    # Download preprocessor
    echo "Downloading preprocessor.joblib..."
    if ! curl -L -o "$PREPROCESSOR_FILE" "${DOWNLOAD_URL_BASE}/preprocessor.joblib"; then
        echo "Failed to download preprocessor.joblib"
        exit 1
    fi
    
    echo "Download complete"
fi

# Verify files exist before starting
if [ ! -f "$MODEL_FILE" ] || [ ! -f "$PREPROCESSOR_FILE" ]; then
    echo "ERROR: Model files not found after download attempt!"
    ls -lh "$MODEL_DIR"
    exit 1
fi

echo "Models verified. File sizes:"
ls -lh "$MODEL_FILE" "$PREPROCESSOR_FILE"

# Start service
echo "Launching Python server..."
exec python src/serve_model.py
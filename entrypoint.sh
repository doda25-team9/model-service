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

# Check if both models exist and are valid (non-empty and binary)
if [ -f "$MODEL_FILE" ] && [ -f "$PREPROCESSOR_FILE" ] && [ -s "$MODEL_FILE" ] && [ -s "$PREPROCESSOR_FILE" ]; then
    # Check if files are actually binary (not HTML error pages)
    if file "$MODEL_FILE" | grep -q "data" && file "$PREPROCESSOR_FILE" | grep -q "data"; then
        echo "Valid models found. Skipping download."
    else
        echo "Models exist but appear corrupted. Re-downloading..."
        rm -f "$MODEL_FILE" "$PREPROCESSOR_FILE"
    fi
fi

# Download if models don't exist or were corrupted
if [ ! -f "$MODEL_FILE" ] || [ ! -f "$PREPROCESSOR_FILE" ]; then
    echo "Downloading models..."
    
    # Ensure directory exists
    mkdir -p "$MODEL_DIR"
    
    # Download model with proper headers and follow redirects
    echo "Downloading model.joblib..."
    curl -L \
         -H "Accept: application/octet-stream" \
         -o "$MODEL_FILE" \
         "${DOWNLOAD_URL_BASE}/model.joblib"
    
    if [ ! -s "$MODEL_FILE" ]; then
        echo "ERROR: model.joblib download failed or is empty"
        ls -lh "$MODEL_DIR"
        exit 1
    fi
    
    # Download preprocessor
    echo "Downloading preprocessor.joblib..."
    curl -L \
         -H "Accept: application/octet-stream" \
         -o "$PREPROCESSOR_FILE" \
         "${DOWNLOAD_URL_BASE}/preprocessor.joblib"
    
    if [ ! -s "$PREPROCESSOR_FILE" ]; then
        echo "ERROR: preprocessor.joblib download failed or is empty"
        ls -lh "$MODEL_DIR"
        exit 1
    fi
    
    echo "Download complete"
fi

# Verify files before starting
echo "Verifying model files..."
ls -lh "$MODEL_FILE" "$PREPROCESSOR_FILE"

if ! file "$MODEL_FILE" | grep -q "data"; then
    echo "ERROR: model.joblib is not a valid binary file!"
    file "$MODEL_FILE"
    head -20 "$MODEL_FILE"
    exit 1
fi

echo "Models verified successfully"

# Start service
echo "Launching Python server..."
exec python src/serve_model.py
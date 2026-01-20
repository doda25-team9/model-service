#!/bin/sh
set -e

# Configuration
MODEL_DIR="${MODEL_DIR:-/app/output}"
MODEL_VERSION="${MODEL_VERSION:-v0.1.0}"
MODEL_FILE="${MODEL_DIR}/model.joblib"
PREPROCESSOR_FILE="${MODEL_DIR}/preprocessor.joblib"
BASE_URL="https://github.com/doda25-team9/model-service/releases/download/${MODEL_VERSION}"

echo "Starting Model Service..."
echo "Model directory: ${MODEL_DIR}"
echo "Model version: ${MODEL_VERSION}"

# Function to check file size
get_size() {
    stat -c%s "$1" 2>/dev/null || stat -f%z "$1" 2>/dev/null || echo 0
}

# Check if models exist and are valid
if [ -f "$MODEL_FILE" ] && [ -f "$PREPROCESSOR_FILE" ]; then
    MODEL_SIZE=$(get_size "$MODEL_FILE")
    PREP_SIZE=$(get_size "$PREPROCESSOR_FILE")
    
    if [ "$MODEL_SIZE" -gt 1000 ] && [ "$PREP_SIZE" -gt 1000 ]; then
        echo "Valid models found (model: ${MODEL_SIZE} bytes, preprocessor: ${PREP_SIZE} bytes)"
        echo "Skipping download."
    else
        echo "Models too small, re-downloading..."
        rm -f "$MODEL_FILE" "$PREPROCESSOR_FILE"
    fi
fi

# Download if needed
if [ ! -f "$MODEL_FILE" ] || [ ! -f "$PREPROCESSOR_FILE" ]; then
    echo "Downloading models from: ${BASE_URL}"
    mkdir -p "$MODEL_DIR"
    
    # Download model with verbose output
    echo "Downloading model.joblib..."
    curl -v -L -o "$MODEL_FILE" "${BASE_URL}/model.joblib" 2>&1 | head -20
    
    MODEL_SIZE=$(get_size "$MODEL_FILE")
    echo "Downloaded: ${MODEL_SIZE} bytes"
    
    if [ "$MODEL_SIZE" -lt 1000 ]; then
        echo "ERROR: model.joblib download failed (only ${MODEL_SIZE} bytes)"
        echo "Content of downloaded file:"
        cat "$MODEL_FILE"
        exit 1
    fi
    
    # Download preprocessor
    echo "Downloading preprocessor.joblib..."
    curl -v -L -o "$PREPROCESSOR_FILE" "${BASE_URL}/preprocessor.joblib" 2>&1 | head -20
    
    PREP_SIZE=$(get_size "$PREPROCESSOR_FILE")
    echo "Downloaded: ${PREP_SIZE} bytes"
    
    if [ "$PREP_SIZE" -lt 1000 ]; then
        echo "ERROR: preprocessor.joblib download failed (only ${PREP_SIZE} bytes)"
        echo "Content of downloaded file:"
        cat "$PREPROCESSOR_FILE"
        exit 1
    fi
    
    echo "Downloads complete!"
fi

echo "Model files ready:"
ls -lh "$MODEL_FILE" "$PREPROCESSOR_FILE"

# Start service
echo "Launching Python server..."
exec python src/serve_model.py
"""
Flask API of the SMS Spam detection model model.
"""
import os

from flask import Flask, jsonify, request, Response
from flasgger import Swagger
from prometheus_client import Counter, Histogram, generate_latest, REGISTRY
import time

from setup_model import get_model_and_preprocessor
from text_preprocessing import _extract_message_len, _text_process # Needed to deserialize the preprocessor

app = Flask(__name__)
swagger = Swagger(app)

# Get model version from environment
MODEL_VERSION = os.getenv('MODEL_VERSION', 'v1')
MODEL_PORT = int(os.getenv('MODEL_PORT', 8081))

model, preprocessor = get_model_and_preprocessor()

# Prometheus metrics
predictions_total = Counter('model_predictions_total', 'Total predictions', ['version', 'result'])
prediction_latency = Histogram('model_prediction_latency_seconds', 'Prediction latency', ['version'])

@app.route('/predict', methods=['POST'])
def predict():
    """
    Predict whether an SMS is Spam.
    ---
    consumes:
      - application/json
    parameters:
        - name: input_data
          in: body
          description: message to be classified.
          required: True
          schema:
            type: object
            required: sms
            properties:
                sms:
                    type: string
                    example: This is an example of an SMS.
    responses:
      200:
        description: "The result of the classification: 'spam' or 'ham'."
    """

    start_time = time.time()
    
    input_data = request.get_json()
    sms = input_data.get('sms')
    processed_sms = preprocessor.transform([sms])
    prediction = model.predict(processed_sms)[0]
    
    # Record metrics
    predictions_total.labels(version=MODEL_VERSION, result=prediction).inc()
    prediction_latency.labels(version=MODEL_VERSION).observe(time.time() - start_time)
    
    res = {
        "result": prediction,
        "classifier": type(model).__name__,
        "sms": sms
    }
    print(res)
    return jsonify(res)

@app.route('/metrics')
def metrics():
    return Response(generate_latest(REGISTRY), mimetype='text/plain')

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=MODEL_PORT, debug=True)

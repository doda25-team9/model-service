from joblib import load

MODEL_LOCAL_PATH = '/app/output/model.joblib'
PREPROCESSOR_LOCAL_PATH = '/app/output/preprocessor.joblib'

def get_model_and_preprocessor():
    model = load('output/model.joblib')
    preprocessor = load('output/preprocessor.joblib')

    return model, preprocessor

# SMS Checker / Backend

The backend of this project provides a simple REST service that can be used to detect spam messages.
We have extended the base project [rohan8594/SMS-Spam-Detection](https://github.com/rohan8594/SMS-Spam-Detection), which introduces several basic classification models, and wrap one of them in a microservice.

The following sections will explain you how to get started.
The project **requires a Python 3.12 environment** to run (tested with 3.12.9).
Use the `requirements.txt` file to restore the required dependencies in your environment.

### Training the Model

To train the model, you have two options.
Either you create a local environment...

    $ python -m venv venv
    $ source venv/bin/activate
    $ pip install -r requirements.txt

... or you train in a Docker container (recommended):

    $ docker run -it --rm -v ./:/root/sms/ python:3.12.9-slim bash
    ... (container startup)
    $ cd /root/sms/
    $ pip install -r requirements.txt

Once all dependencies have been installed, the data can be preprocessed and the model trained by creating the output folder and invoking three commands:

    $ mkdir output
    $ python src/read_data.py
    Total number of messages:5574
    ...
    $ python src/text_preprocessing.py
    [nltk_data] Downloading package stopwords to /root/nltk_data...
    [nltk_data]   Unzipping corpora/stopwords.zip.
    ...
    $ python src/text_classification.py

The resulting model files will be placed as `.joblib` files in the `output/` folder.

### Serving Recommendations

To make the models accessible, you need to start the microservice by running the `src/serve_model.py` script from within the virtual environment that you created before, or in a fresh Docker container (recommended):

    $ docker run -it --rm -p 8081:8081 -v ./:/root/sms/ python:3.12.9-slim bash
    ... (container startup)
    $ cd /root/sms/
    $ pip install -r requirements.txt
    $ python src/serve_model.py

The server will start on port 8081.
Once its startup has finished, you can either access [localhost:8081/apidocs](http://localhost:8081/apidocs) in your browser to interact with the service, or you send `POST` requests to request predictions, for example with `curl`:

    $ curl -X POST "http://localhost:8081/predict" -H "Content-Type: application/json" -d '{"sms": "test ..."}'
    {
      "classifier": "decision tree",
      "result": "ham",
      "sms": "test ..."
    }

## Requirements

- Docker with Buildx support
- Trained model files (generated separately, not included in repo)

## Building and Running (F3 & F6)

Build the Docker image:

```
docker build -t model-service:latest .
```

Run the container (requires trained models in output/ folder):

```
docker run -p 8081:8081 -v ./output:/app/output model-service:latest
```

The service starts on port 8081.

You can also change the port by specifying `MODEL_PORT` env:

```
docker run -p 8082:8082 -e MODEL_PORT=8082 -v ./output:/app/output model-service:latest
```

Run the container (requires trained models in output/ folder):

Test the API:

```
curl -X POST "http://localhost:8081/predict" -H "Content-Type: application/json" -d '{"sms": "Win a free prize!"}'
```

Or visit: http://localhost:8081/apidocs

## Multi-Architecture Support (F4)

Supports both amd64 (Intel/AMD) and arm64 (Apple Silicon, ARM servers).

Setup multi-platform builder (first time only):

```
docker buildx create --name multiarch-builder --use
docker buildx inspect --bootstrap
```

Build for both architectures:

```
docker buildx build --platform linux/amd64,linux/arm64 -t model-service:latest .
```

Build for specific architecture:

```
docker buildx build --platform linux/arm64 -t model-service:latest --load .
docker buildx build --platform linux/amd64 -t model-service:latest --load .
```

## Testing App and Model-Service Together

Terminal 1 - Start model-service:

```
cd model-service
docker run -p 8081:8081 -v ./output:/app/output model-service:latest
```

Terminal 2 - Start app:

```
cd app
docker run -p 8080:8080 -e MODEL_HOST=http://host.docker.internal:8081 app:latest
```

Terminal 3 - Test in browser:

Open: http://localhost:8080/sms

Type a message (e.g., "Win a free prize!") and click Check to verify the app communicates with the model service and returns a spam/ham prediction.

## Automated Container Image Releases (F8)

The repository includes a Github Actions workflow (`.github/workflows/release.yml`) that automatically builds and publishes versioned container images of the model-service to the GitHub Container Registry (GHCR).

### Single Source of Truth for Versions

The version of the model-service is stored in:
`src/version.py`
Example:
`__version__ = "0.1.0"`

This file acts as the single source of truth for versioning.
Whenever a new release is needed for the model-service repository, only this file must be updated.

### How the Workflow Works

This workflow is triggered whenever a new Git tag matching the pattern `v*` is pushed.
Once triggered, the pipeline executes the following steps:

1. Checks out the repository
2. Reads the version number from `src/version.py`
3. Builds a Docker image for both `linux/amd64` and `linux/arm64`
4. Tags the image using the extracted version:
   `ghcr.io/doda25-team9/model-service:<version>`
5. Also tags and updates the `latest` tag
6. Pushes both tags to GHCR

### Viewing Published Images

Released images are available at:
`https://github.com/doda25-team9/model-service/pkgs/container/model-service`

### Running a Released Image

To run a published release:

```
docker pull ghcr.io/doda25-team9/model-service:<version>
docker run -p 8081:8081 -v ./output:/app/output ghcr.io/doda25-team9/model-service:<version>
```

To note: to run the above image, you need the trained models in your `/output` file locally. Check the section "Training the Model" above to ensure you have them in the correct folder.

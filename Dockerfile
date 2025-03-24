# Start from an NVIDIA CUDA base for GPU support (Ubuntu 22.04)
FROM nvidia/cuda:12.6.3-cudnn-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install Python 3.12
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    git \
    wget \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y --no-install-recommends \
    python3.12 python3.12-dev python3.12-venv \
    nvidia-cuda-toolkit \
    && rm -rf /var/lib/apt/lists/*

# Install pip
RUN wget https://bootstrap.pypa.io/get-pip.py && \
    python3.12 get-pip.py && \
    rm get-pip.py

WORKDIR /app

# Clone the OmniParser repository
RUN git clone https://github.com/microsoft/OmniParser.git /app

# We need to downgrade Transformers version from what's in the requirements.txt as 4.50 hits an error
RUN sed -i 's/transformers==.*$/transformers==4.45.0/g' /app/requirements.txt

RUN python3.12 -m pip install --upgrade pip && \
    python3.12 -m pip install --no-cache-dir -r /app/requirements.txt huggingface_hub

# Download OmniParser model weights from HF
RUN mkdir -p /app/weights && \
    for folder in icon_caption icon_detect; do \
        huggingface-cli download microsoft/OmniParser-v2.0 --local-dir /app/weights \
            --repo-type model --include "$folder/*"; \
    done && \
    mv /app/weights/icon_caption /app/weights/icon_caption_florence

# Expose port for FastAPI
EXPOSE 8000

# Set environment variables for RunPod
ENV PYTHONPATH=/app
ENV RUNPOD_DEBUG=true

WORKDIR /app/omnitool/omniparserserver

CMD ["python3.12", "-m", "omniparserserver", "--host", "0.0.0.0"]
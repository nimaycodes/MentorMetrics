# Use Python 3.10 to match wheels for mediapipe/whl-heavy packages
FROM python:3.10-slim

# Install system packages and ffmpeg
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      wget ca-certificates build-essential libssl-dev libffi-dev libpq-dev \
      libsndfile1 libgl1 libglib2.0-0 ffmpeg xz-utils && \
    rm -rf /var/lib/apt/lists/*

# Set workdir
WORKDIR /app

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Optional: copy a constraints file if you have one (recommended)
# COPY constraints.txt .

# Install pip/tools, install CPU torch first (from PyTorch index), then deps.
# Use --prefer-binary to prefer wheels (reduces resolver/build time).
RUN python -m pip install --upgrade pip setuptools wheel && \
    pip install --index-url https://download.pytorch.org/whl/cpu \
      --prefer-binary torch==2.9.1+cpu --no-cache-dir || true && \
    pip install --no-cache-dir --prefer-binary -r requirements.txt

# Copy app files
COPY . .

# Expose and run
EXPOSE 8000
CMD ["uvicorn", "your_module:app", "--host", "0.0.0.0", "--port", "8000"]

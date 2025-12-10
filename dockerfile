FROM python:3.10-slim

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

# Install system libs & build deps required by some Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget xz-utils ca-certificates build-essential libssl-dev libffi-dev libpq-dev gcc \
    libsndfile1 libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Download static ffmpeg binary (prebuilt) and install it — avoids apt ffmpeg issues
RUN wget -qO /tmp/ffmpeg.tar.xz https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz \
    && mkdir -p /tmp/ffmpeg && tar -xJf /tmp/ffmpeg.tar.xz -C /tmp/ffmpeg --strip-components=1 \
    && mv /tmp/ffmpeg/ffmpeg /usr/local/bin/ffmpeg \
    && mv /tmp/ffmpeg/ffprobe /usr/local/bin/ffprobe \
    && chmod +x /usr/local/bin/ffmpeg /usr/local/bin/ffprobe \
    && rm -rf /tmp/ffmpeg /tmp/ffmpeg.tar.xz

# Copy requirements first so we can cache layer after dependency changes
COPY requirements.txt .

# Upgrade pip, install CPU-only PyTorch first (smaller), then install the rest of requirements.
RUN python -m pip install --upgrade pip setuptools wheel && \
    pip install --index-url https://download.pytorch.org/whl/cpu torch==2.9.1+cpu --no-cache-dir || true && \
    pip install --no-cache-dir -r requirements.txt

# Create non-root user and set ownership
RUN useradd --create-home appuser
COPY . .
RUN chown -R appuser:appuser /app
USER appuser

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8080}"]

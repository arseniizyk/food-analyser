FROM paddlepaddle/paddle:3.3.1-gpu-cuda13.0-cudnn9.13

# The base image puts /usr/local/cuda-13.0/compat first in LD_LIBRARY_PATH.
# That dir holds a forward-compat *stub* libcuda which needs a real NVIDIA
# kernel driver (/proc/driver/nvidia/version). Under Docker Desktop WSL2 the
# driver's libcuda lives in /usr/lib/x86_64-linux-gnu and the stub makes
# cuInit fail with CUDA_ERROR_NO_DEVICE, so Paddle sees 0 GPUs and
# PaddleOCR-VL crashes with "use wrong place, Please check". Drop the stub;
# the real driver libcuda is resolved via the ldconfig cache instead.
ENV LD_LIBRARY_PATH="/usr/local/cuda-13.0/targets/x86_64-linux/lib:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:/usr/local/cuda/lib64"

WORKDIR /app

RUN apt-get update && apt-get install -y \
    libgl1 \
    libglib2.0-0 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python3", "main.py"]
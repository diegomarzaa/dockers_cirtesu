# =============================================================================
# diegomarza/ros2-da3-dev — ROS 2 + DA3 + streaming dependencies
# =============================================================================
# Base:
#   - Starts from diegomarza/ros2-dev-base
#   - Keeps ROS 2 and DA3 in the same system Python interpreter
#   - Avoids virtual environments on purpose to simplify ROS2 wrapper imports
#
# Build:
#   docker compose build ros2-da3-dev
# =============================================================================

FROM diegomarza/ros2-dev-base:latest

ARG USERNAME

# ── Root-only layers ──────────────────────────────────────────────────────────
USER root
ENV HOME=/root

# Runtime libs used by OpenCV/video workflows in DA3 streaming.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Install DA3 + streaming dependencies in the same Python used by ROS2.
# Important: use --system (no venv) to keep one Python environment.
RUN set -eux; \
    uv pip install --system numpy==1.26.4; \
    uv pip install --system --index-url https://download.pytorch.org/whl/cu121 \
        torch==2.5.1 \
        torchvision==0.20.1; \
    uv pip install --system \
        addict \
        einops \
        huggingface_hub \
        imageio \
        matplotlib \
        omegaconf \
        opencv-python \
        requests \
        safetensors \
        tqdm \
        trimesh \
        typer \
        faiss-gpu \
        numba \
        pandas \
        prettytable \
        pypose \
        pyyaml \
        rich \
        scipy \
        scikit-learn

# Bring local DA3 repository from additional_contexts and install editable.
COPY --from=depth_anything_3 --chown=${USERNAME}:${USERNAME} . /opt/depth-anything-3
RUN uv pip install --system --no-deps -e /opt/depth-anything-3

# ── Back to developer user ────────────────────────────────────────────────────
USER ${USERNAME}
ENV HOME=/home/${USERNAME}
ENV HF_HOME=/home/${USERNAME}/.cache/huggingface

# ── Smoke tests (no model downloads) ──────────────────────────────────────────
RUN bash -lc 'set -eo pipefail; \
    source /opt/ros/humble/setup.bash; \
    python3 -c "import rclpy; print(\"rclpy_ok\")"; \
    python3 -c "import torch, torchvision; print(torch.__version__, torch.version.cuda, torchvision.__version__)"; \
    python3 -c "from depth_anything_3.api import DepthAnything3; print(DepthAnything3.__name__)"; \
    python3 -c "import faiss, pypose, numba, pandas; print(\"streaming_deps_ok\")"'

WORKDIR /home/${USERNAME}/DockerWorkspace
CMD ["/bin/bash"]

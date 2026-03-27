# =============================================================================
# diegomarza/da3 — Depth Anything 3 base image
# =============================================================================
# Builds on diegomarza/ros2-dev-base and codifies the DA3 stack already validated
# manually inside the running container.
#
# Important:
# - This image intentionally keeps the DA3 scope narrow: core Python API + CLI.
# - ROS 2 remains available from the parent image, but the dedicated wrapper
#   layer will live in a future derived image.
# - The repo is baked into the same path used at runtime, so editable installs
#   and the mounted workspace share the exact same import path.

# Build from the workspace root so Docker can copy the local DA3 checkout:
#   docker build -f docker/da3/Dockerfile -t diegomarza/da3:latest .
# =============================================================================

FROM diegomarza/ros2-dev-base:latest

ARG USERNAME=diego

# ── Root-only setup ──────────────────────────────────────────────────────────
# Docker keeps HOME inherited from the parent image unless we override it.
# While running root-owned layers, force HOME=/root to avoid root-owned caches
# under /home/${USERNAME}.
USER root
ENV HOME=/root

ENV VIRTUAL_ENV=/opt/venvs/da3
ENV HF_HOME=/home/${USERNAME}/.cache/huggingface

RUN set -eux; \
    mkdir -p /opt/venvs; \
    uv venv "${VIRTUAL_ENV}" --python python3.10 --seed; \
    chown -R ${USERNAME}:${USERNAME} /opt/venvs

# ── Python environment defaults ─────────────────────────────────────────────
# Keep the DA3 venv first in PATH so `python` and `pip` naturally resolve to
# /opt/venvs/da3 without extra aliases or PYTHONPATH tweaks.
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

# ── Back to developer user ──────────────────────────────────────────────────
ENV HOME=/home/${USERNAME}
USER ${USERNAME}

# ── Install the validated DA3 base stack ────────────────────────────────────
# Keep the order explicit:
# 1. Freeze the audited numeric stack first.
# 2. Install the audited base runtime packages.
# 3. Install the local patched DA3 repo in editable mode without re-resolving
#    dependencies.
#
# Last validated direct runtime resolutions in a fresh build on 2026-03-26:
# addict==2.4.0, einops==0.8.2, huggingface_hub==1.8.0, imageio==2.37.3,
# matplotlib==3.10.8, omegaconf==2.3.0, opencv-python==4.11.0.86,
# pillow==12.1.1, requests==2.33.0, safetensors==0.7.0, tqdm==4.67.3,
# trimesh==4.11.5, typer==0.24.1.
RUN set -eux; \
    uv pip install --python "${VIRTUAL_ENV}/bin/python" numpy==1.26.4; \
    uv pip install --python "${VIRTUAL_ENV}/bin/python" \
        --index-url https://download.pytorch.org/whl/cu121 \
        torch==2.5.1 torchvision==0.20.1; \
    uv pip install --python "${VIRTUAL_ENV}/bin/python" \
        addict \
        einops \
        huggingface_hub \
        imageio \
        matplotlib \
        omegaconf \
        opencv-python \
        pillow \
        requests \
        safetensors \
        tqdm \
        trimesh \
        typer

COPY --chown=${USERNAME}:${USERNAME} Repositories/Depth-Anything-3 /home/${USERNAME}/Cirtesu/Repositories/Depth-Anything-3

RUN set -eux; \
    uv pip install --python "${VIRTUAL_ENV}/bin/python" --no-deps -e /home/${USERNAME}/Cirtesu/Repositories/Depth-Anything-3

# ── Smoke tests that do not require a GPU or model download ─────────────────
RUN set -eux; \
    python -c "import cv2; import torch; from depth_anything_3.api import DepthAnything3; print(f'cv2={cv2.__version__}'); print(f'torch={torch.__version__}'); print(f'torch_cuda_runtime={torch.version.cuda}'); print(f'api_class={DepthAnything3.__name__}')"

RUN set -eux; \
    da3 --help > /dev/null

RUN bash -lc 'set -eo pipefail; source /opt/ros/humble/setup.bash; python -c "import rclpy; print(f\"rclpy={rclpy.__file__}\")"'

WORKDIR /home/${USERNAME}/Cirtesu
CMD ["/bin/bash"]

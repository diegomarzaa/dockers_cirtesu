# =============================================================================
# diegomarza/ros2-dev-base — Complete ROS 2 Humble development environment
# =============================================================================
# The most complete official ROS 2 image (desktop-full) plus all dev tools
# needed for building packages, debugging, and general robotics work.
#
# Runs as a non-root user with passwordless sudo. USERNAME, USER_UID and
# USER_GID must be passed as build args, normally from docker-compose.yml and
# the machine-local .env file.
#
# Used as the shared base for all project-specific images (DA3, Stonefish, etc.)
# so they share Docker layers and save disk space.
#
# Build:
#   docker build -t diegomarza/ros2-dev-base:latest .
#
#   # Pass the user configured for this machine:
#   docker build -t diegomarza/ros2-dev-base:latest \
#     --build-arg USERNAME=usuario \
#     --build-arg USER_UID=$(id -u) \
#     --build-arg USER_GID=$(id -g) .
#
# =============================================================================

FROM osrf/ros:humble-desktop-full

ENV DEBIAN_FRONTEND=noninteractive

# ── Security refresh for inherited Ubuntu/ROS packages ──────────────────────
RUN apt-get update && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

# ── Build & compilation tools ────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    pkg-config \
    git \
    && rm -rf /var/lib/apt/lists/*

# ── Python development ──────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip \
    python3-dev \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# ── ROS 2 development tools ─────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-colcon-common-extensions \
    python3-colcon-mixin \
    python3-rosdep \
    python3-vcstool \
    ros-humble-rmw-cyclonedds-cpp \
    && rm -rf /var/lib/apt/lists/*

# ── Editors ──────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    vim \
    gedit \
    && rm -rf /var/lib/apt/lists/*

# ── System utilities (includes sudo) ────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    wget \
    curl \
    htop \
    tmux \
    tree \
    less \
    unzip \
    iputils-ping \
    net-tools \
    dnsutils \
    && rm -rf /var/lib/apt/lists/*

# ── GUI / X11 support ───────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    x11-apps \
    mesa-utils \
    dbus-x11 \
    libxkbcommon-x11-0 \
    && rm -rf /var/lib/apt/lists/*

# ── rosdep initialization (must happen as root, before user switch) ──────────
RUN rosdep init 2>/dev/null || true && rosdep update

# ── Create non-root user ────────────────────────────────────────────────────
# Compose should pass the arguments, from .env file
ARG USERNAME
ARG USER_UID
ARG USER_GID

RUN set -eux; \
    : "${USERNAME:?Build arg USERNAME is required}"; \
    : "${USER_UID:?Build arg USER_UID is required}"; \
    : "${USER_GID:?Build arg USER_GID is required}"; \
    if ! getent group "${USER_GID}" >/dev/null; then \
        groupadd --gid "${USER_GID}" "${USERNAME}"; \
    fi; \
    useradd --uid "${USER_UID}" --gid "${USER_GID}" -m -s /bin/bash "${USERNAME}"; \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}"; \
    chmod 0440 "/etc/sudoers.d/${USERNAME}"

# ── uv: Python package manager ─────────────────────────────────────────
# Install as root to /usr/local/bin so it's available to all users.
RUN curl -LsSf https://astral.sh/uv/install.sh | env INSTALLER_NO_MODIFY_PATH=1 sh && \
    mv /root/.local/bin/uv /usr/local/bin/uv && \
    mv /root/.local/bin/uvx /usr/local/bin/uvx

# ── Switch to non-root user ─────────────────────────────────────────────────
USER ${USERNAME}
# IMPORTANT: If a child image later switches back to `USER root`, Docker keeps
# this HOME value unless the child overrides it. Root-owned tools would then
# create caches under /home/${USERNAME} (for example /home/${USERNAME}/.cache).
# In child images, set `ENV HOME=/root` for root-only layers and restore
# `ENV HOME=/home/${USERNAME}` before switching back to the developer user.
ENV HOME=/home/${USERNAME}

# ── Shell configuration (as user) ───────────────────────────────────────────
RUN echo 'source /opt/ros/humble/setup.bash' >> ~/.bashrc

CMD ["/bin/bash"]

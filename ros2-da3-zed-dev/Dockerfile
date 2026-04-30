# =============================================================================
# diegomarza/ros2-da3-zed-dev — ROS 2 + DA3 + ZED SDK + ZED ROS 2 Wrapper
# =============================================================================
# Final objective:
#   - Keep ROS 2 + DA3 in the same Python environment from ros2-da3-dev.
#   - Add CUDA Toolkit explicitly.
#   - Install the official ZED SDK without duplicating CUDA.
#   - Install pyzed into the same system Python.
#   - Build zed-ros2-wrapper inside /opt/zed_ros2_ws.
# =============================================================================

FROM diegomarza/ros2-da3-dev:latest

ARG USERNAME

# Keep these as build args so you can update them from docker-compose/.env.
ARG ROS_DISTRO=humble
ARG CUDA_TOOLKIT_PKG=cuda-toolkit-12-4
ARG ZED_SDK_VERSION=5.2.3
ARG ZED_CUDA_MAJOR=12
ARG ZED_UBUNTU_MAJOR=22
ARG ZED_ROS2_WRAPPER_REF=v5.2.2

USER root
ENV HOME=/root
ENV DEBIAN_FRONTEND=noninteractive

ENV ROS_DISTRO=${ROS_DISTRO}
ENV ZED_SDK_ROOT_DIR=/usr/local/zed
ENV CUDA_HOME=/usr/local/cuda
ENV CUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda
ENV PATH=/usr/local/cuda/bin:/usr/local/zed/bin:/usr/local/zed/tools:${PATH}
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/zed/lib:${LD_LIBRARY_PATH}

# Keep NVIDIA capabilities aligned with ZED + CUDA + video + GUI tooling.
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics,video,display

# Re-assert passwordless sudo for the inherited developer user.
RUN set -eux; \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}"; \
    chmod 0440 "/etc/sudoers.d/${USERNAME}"

# Base runtime/build deps needed by ZED SDK, pyzed and wrapper build.
# libturbojpeg is needed by pyzed.sl on Ubuntu 22.04.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    file \
    gnupg \
    wget \
    git \
    build-essential \
    cmake \
    pkg-config \
    usbutils \
    v4l-utils \
    udev \
    zstd \
    less \
    libusb-1.0-0 \
    libturbojpeg \
    libpng-dev \
    libgomp1 \
    python3-pip \
    python3-dev \
    python3-wheel \
    && rm -rf /var/lib/apt/lists/*

# Match Stereolabs' own Dockerfiles: the SDK build/config sometimes expects
# libusb-1.0.so, while Ubuntu installs libusb-1.0.so.0 with the runtime package.
RUN ln -sf /lib/x86_64-linux-gnu/libusb-1.0.so.0 /usr/lib/x86_64-linux-gnu/libusb-1.0.so

# Install CUDA Toolkit from NVIDIA's apt repo.
# Use cuda-toolkit-12-4, not the generic "cuda" metapackage, to avoid trying to
# install/manage host drivers inside the container.
RUN set -eux; \
    wget -q https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb -O /tmp/cuda-keyring.deb; \
    dpkg -i /tmp/cuda-keyring.deb; \
    rm -f /tmp/cuda-keyring.deb; \
    apt-get update; \
    apt-get install -y --no-install-recommends "${CUDA_TOOLKIT_PKG}"; \
    rm -rf /var/lib/apt/lists/*

# Install ZED SDK.
# Important:
#   - skip_cuda because CUDA Toolkit is already installed above.
#   - do NOT use skip_tools because you asked for the full development pack.
RUN set -eux; \
    installer="/tmp/ZED_SDK_Linux_Ubuntu.run"; \
    url="https://download.stereolabs.com/zedsdk/${ZED_SDK_VERSION}/cu${ZED_CUDA_MAJOR}/ubuntu${ZED_UBUNTU_MAJOR}"; \
    echo "Downloading ZED SDK from: ${url}"; \
    curl -fsSL "${url}" -o "${installer}"; \
    file "${installer}"; \
    test -s "${installer}"; \
    file "${installer}" | grep -Eq 'shell script|executable'; \
    chmod +x "${installer}"; \
    "${installer}" -- silent skip_cuda; \
    rm -f "${installer}"; \
    ldconfig

# Install ZED Python API into the same system Python used by ROS 2 and DA3.
RUN set -eux; \
    umask 022; \
    python3 /usr/local/zed/get_python_api.py; \
    test -d /usr/local/lib/python3.10/dist-packages/pyzed; \
    pyzed_dist_info="$(find /usr/local/lib/python3.10/dist-packages -maxdepth 1 -type d -name 'pyzed-*.dist-info' | head -n 1)"; \
    test -n "${pyzed_dist_info}"; \
    chmod -R a+rX /usr/local/lib/python3.10/dist-packages/pyzed "${pyzed_dist_info}"

# Install and build the official ZED ROS 2 wrapper.
# Build in /opt so your bind-mounted workspace does not hide or overwrite it.
RUN set -eux; \
    mkdir -p /opt/zed_ros2_ws/src; \
    cd /opt/zed_ros2_ws/src; \
    git clone --depth=1 --branch "${ZED_ROS2_WRAPPER_REF}" https://github.com/stereolabs/zed-ros2-wrapper.git

# Resolve ROS deps and compile.
# CMAKE_LIBRARY_PATH points to CUDA stubs because real libcuda.so.1 is mounted
# only at runtime by NVIDIA Container Toolkit when using --gpus all.
RUN /bin/bash -lc "set -eo pipefail; \
    source /opt/ros/${ROS_DISTRO}/setup.bash; \
    cd /opt/zed_ros2_ws; \
    apt-get update; \
    rosdep update; \
    rosdep install --from-paths src --ignore-src -r -y; \
    colcon build \
      --symlink-install \
      --packages-skip zed_debug \
      --event-handlers console_direct+ \
      --cmake-args \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs \
        -DCMAKE_CXX_FLAGS='-Wl,--allow-shlib-undefined'; \
    rm -rf /var/lib/apt/lists/*"

# Source the ZED ROS 2 workspace automatically.
RUN set -eux; \
    echo "source /opt/ros/${ROS_DISTRO}/setup.bash" > /etc/profile.d/ros2.sh; \
    echo "source /opt/zed_ros2_ws/install/local_setup.bash" > /etc/profile.d/zed_ros2_ws.sh; \
    echo "source /opt/zed_ros2_ws/install/local_setup.bash" >> "/home/${USERNAME}/.bashrc"; \
    chown "${USERNAME}:${USERNAME}" "/home/${USERNAME}/.bashrc"

# Build-time smoke checks that do not require GPU-mounted libcuda.so.1.
RUN set -eux; \
    test -x /usr/local/cuda/bin/nvcc; \
    test -d /usr/local/zed; \
    test -d /usr/local/zed/lib; \
    test -d /usr/local/zed/tools; \
    test -d /opt/zed_ros2_ws/install

USER ${USERNAME}
ENV HOME=/home/${USERNAME}
WORKDIR /home/${USERNAME}/depth_anything_ws

CMD ["/bin/bash"]

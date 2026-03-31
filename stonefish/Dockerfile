# =============================================================================
# diegomarza/stonefish — ROS 2 + Stonefish base image
# =============================================================================
# Keeps Stonefish separate from DA3, matching the current modular Docker layout:
#   diegomarza/ros2-dev-base -> diegomarza/stonefish
#
# Scope of this layer:
# - Install the ROS 2 and system packages needed by the local stonefish_ws.
# - Install the system/toolchain dependencies needed by Stonefish.
# - Provide helper scripts to build Stonefish + the mounted ROS 2 overlay from
#   /home/diego/Cirtesu/Simulations/stonefish_ws on demand.
#
# Local sources used for the dependency and version choices:
# - Simulations/stonefish_ws/src/stonefish/README.md
# - Simulations/stonefish_ws/src/stonefish/CMakeLists.txt
# - Simulations/stonefish_ws/src/stonefish_ros2/CMakeLists.txt
# - agentdocs/changelog.md
#
# Build from the workspace root:
#   docker build -f docker/stonefish/Dockerfile -t diegomarza/stonefish:latest .
# =============================================================================

FROM diegomarza/ros2-dev-base:latest

ARG USERNAME=diego
ARG ROS_DISTRO=humble
USER root
ENV HOME=/root

RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    libavcodec-dev \
    libavutil-dev \
    libfreetype6-dev \
    libgl1-mesa-dev \
    libglm-dev \
    libglu1-mesa-dev \
    libsdl2-dev \
    libswscale-dev \
    mesa-utils \
    python3-numpy \
    ros-${ROS_DISTRO}-camera-info-manager \
    ros-${ROS_DISTRO}-controller-manager \
    ros-${ROS_DISTRO}-cv-bridge \
    ros-${ROS_DISTRO}-depth-image-proc \
    ros-${ROS_DISTRO}-image-transport \
    ros-${ROS_DISTRO}-image-transport-plugins \
    ros-${ROS_DISTRO}-joint-state-broadcaster \
    ros-${ROS_DISTRO}-joint-state-publisher \
    ros-${ROS_DISTRO}-joint-state-publisher-gui \
    ros-${ROS_DISTRO}-joint-trajectory-controller \
    ros-${ROS_DISTRO}-pcl-conversions \
    ros-${ROS_DISTRO}-robot-state-publisher \
    ros-${ROS_DISTRO}-ros2-control \
    ros-${ROS_DISTRO}-ros2-controllers \
    ros-${ROS_DISTRO}-rqt \
    ros-${ROS_DISTRO}-rqt-common-plugins \
    ros-${ROS_DISTRO}-rqt-image-view \
    ros-${ROS_DISTRO}-rqt-joint-trajectory-controller \
    ros-${ROS_DISTRO}-rtabmap-ros \
    ros-${ROS_DISTRO}-rviz-imu-plugin \
    ros-${ROS_DISTRO}-teleop-twist-keyboard \
    ros-${ROS_DISTRO}-tf2-ros \
    ros-${ROS_DISTRO}-xacro \
    v4l-utils \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

RUN add-apt-repository ppa:ubuntu-toolchain-r/test -y \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        gcc-13 \
        g++-13 \
        libstdc++-13-dev \
    && rm -rf /var/lib/apt/lists/*

ENV CC=/usr/bin/gcc-13
ENV CXX=/usr/bin/g++-13

RUN set -eux; \
    ln -sf /home/${USERNAME}/Cirtesu/docker/stonefish/scripts/build_stonefish_ws.sh /usr/local/bin/build_stonefish_ws; \
    ln -sf /home/${USERNAME}/Cirtesu/docker/stonefish/scripts/source_stonefish_env.sh /usr/local/bin/source_stonefish_env

ENV HOME=/home/${USERNAME}
USER ${USERNAME}

RUN echo 'source /usr/local/bin/source_stonefish_env' >> "/home/${USERNAME}/.bashrc"

WORKDIR /home/${USERNAME}/Cirtesu
CMD ["/bin/bash"]

# =============================================================================
# diegomarza/da3-ros2-wrapper — ROS 2 wrapper layer on top of DA3
# =============================================================================
# This image keeps the hierarchy explicit:
#   diegomarza/ros2-dev-base -> diegomarza/da3 -> diegomarza/da3-ros2-wrapper
#
# Scope of this layer:
# - Fetch the wrapper from a remote fork/reference during the build.
# - Build only the validated ROS 2 package with colcon.
# - Keep DA3's Python venv as the single Python environment.
# - Add only the test-time Python pieces that ROS pytest plugins expect in that
#   venv (`pytest`, `lark`), without reopening all system dist-packages.
# - Keep only the built ROS 2 overlay in the final image, not the cloned repo.
#
# Build from the workspace root:
#   docker build -f docker/da3-ros2-wrapper/Dockerfile \
#     -t diegomarza/da3-ros2-wrapper:latest .
# =============================================================================

FROM diegomarza/da3:latest

ARG USERNAME=diego
ARG WRAPPER_REPO_URL=https://github.com/diegomarzaa/GerdsenAI-Depth-Anything-3-ROS2-Wrapper.git
ARG WRAPPER_REPO_REF=main

USER root
ENV HOME=/root
ENV ROS2_WRAPPER_WS=/home/${USERNAME}/ros2_wrapper_ws
ENV WRAPPER_REPO_NAME=GerdsenAI-Depth-Anything-3-ROS2-Wrapper
ENV WRAPPER_SRC_DIR=/home/${USERNAME}/ros2_wrapper_ws/src/GerdsenAI-Depth-Anything-3-ROS2-Wrapper

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends "ros-${ROS_DISTRO}-v4l2-camera"; \
    rm -rf /var/lib/apt/lists/*

ENV HOME=/home/${USERNAME}
USER ${USERNAME}

RUN set -eux; \
    mkdir -p "${ROS2_WRAPPER_WS}/src"

RUN bash -lc 'set -eo pipefail; \
    git clone --depth 1 --branch "${WRAPPER_REPO_REF}" "${WRAPPER_REPO_URL}" "${WRAPPER_SRC_DIR}"'

RUN set -eux; \
    uv pip install --python "${VIRTUAL_ENV}/bin/python" pytest lark

RUN bash -lc 'set -eo pipefail; \
    source /opt/ros/humble/setup.bash; \
    cd "${ROS2_WRAPPER_WS}"; \
    colcon build \
        --packages-select depth_anything_3_ros2 \
        --event-handlers console_direct+'

RUN bash -lc 'set -eo pipefail; \
    source /opt/ros/humble/setup.bash; \
    source "${ROS2_WRAPPER_WS}/install/setup.bash"; \
    python -c "import rclpy; import depth_anything_3_ros2.da3_inference; import depth_anything_3_ros2.depth_anything_3_node; print(\"wrapper_imports_ok\")"'

RUN bash -lc 'set -eo pipefail; \
    source /opt/ros/humble/setup.bash; \
    source "${ROS2_WRAPPER_WS}/install/setup.bash"; \
    python -c "from depth_anything_3_ros2.da3_inference import DA3InferenceWrapper; wrapper = DA3InferenceWrapper(model_name=\"depth-anything/DA3-SMALL\", device=\"cpu\"); print(type(wrapper).__name__)"'

RUN set -eux; \
    rm -rf "${ROS2_WRAPPER_WS}/src" "${ROS2_WRAPPER_WS}/build" "${ROS2_WRAPPER_WS}/log"; \
    echo "source ${ROS2_WRAPPER_WS}/install/setup.bash" >> "/home/${USERNAME}/.bashrc"

WORKDIR /home/${USERNAME}
CMD ["/bin/bash"]

#!/usr/bin/env bash
set -euo pipefail

ROS_DISTRO_VALUE="${ROS_DISTRO:-humble}"
CIRTESU_ROOT="${CIRTESU_ROOT:-/home/diego/Cirtesu}"
STONEFISH_WS="${STONEFISH_WS:-${CIRTESU_ROOT}/Simulations/stonefish_ws}"
STONEFISH_SRC="${STONEFISH_SRC:-${STONEFISH_WS}/src/stonefish}"
STONEFISH_BUILD_DIR="${STONEFISH_BUILD_DIR:-${STONEFISH_WS}/build/stonefish_core}"
STONEFISH_INSTALL_PREFIX="${STONEFISH_INSTALL_PREFIX:-${STONEFISH_WS}/stonefish_install}"
STONEFISH_INCLUDE_BLUEROV="${STONEFISH_INCLUDE_BLUEROV:-0}"
SKIP_KEYS="pcl microstrain_inertial_driver"

log_step() {
    printf '\n==> %s\n' "$1"
}

# ROS 2 setup scripts are not consistently safe under `set -u`.
log_step "Sourcing ROS 2 environment from /opt/ros/${ROS_DISTRO_VALUE}"
set +u
source "/opt/ros/${ROS_DISTRO_VALUE}/setup.bash"
set -u

PACKAGES=(
    alpha_description
    cirtesu_stonefish
    peacetolero_description
    peacetolero_stonefish
    stonefish_ros2
)

if [ "${STONEFISH_INCLUDE_BLUEROV}" = "1" ]; then
    PACKAGES+=(bluerov2_cirtesu_core)
fi

ROSDEP_PATHS=()
for package_name in "${PACKAGES[@]}"; do
    ROSDEP_PATHS+=("src/${package_name}")
done

if [ ! -d "${STONEFISH_WS}/src" ]; then
    echo "Stonefish workspace not found at ${STONEFISH_WS}" >&2
    exit 1
fi

if [ ! -f "${STONEFISH_SRC}/CMakeLists.txt" ]; then
    echo "Stonefish source not found at ${STONEFISH_SRC}" >&2
    exit 1
fi

log_step "Using workspace: ${STONEFISH_WS}"
printf 'Packages: %s\n' "${PACKAGES[*]}"
printf 'rosdep paths: %s\n' "${ROSDEP_PATHS[*]}"
printf 'skip-keys: %s\n' "${SKIP_KEYS}"
printf 'stonefish source: %s\n' "${STONEFISH_SRC}"
printf 'stonefish build: %s\n' "${STONEFISH_BUILD_DIR}"
printf 'stonefish install: %s\n' "${STONEFISH_INSTALL_PREFIX}"

cd "${STONEFISH_WS}"

log_step "Fixing ownership for build/install/log if needed"
for workspace_dir in build install log; do
    if [ -e "${workspace_dir}" ]; then
        sudo chown -R "$(id -u):$(id -g)" "${workspace_dir}"
        printf '  fixed ownership: %s\n' "${workspace_dir}"
    else
        printf '  not present yet: %s\n' "${workspace_dir}"
    fi
done

log_step "Building Stonefish core library"
mkdir -p "${STONEFISH_BUILD_DIR}" "${STONEFISH_INSTALL_PREFIX}"
cmake -S "${STONEFISH_SRC}" -B "${STONEFISH_BUILD_DIR}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${STONEFISH_INSTALL_PREFIX}"
cmake --build "${STONEFISH_BUILD_DIR}" --parallel "$(nproc)"
cmake --install "${STONEFISH_BUILD_DIR}"

log_step "Activating Stonefish install prefix"
export CMAKE_PREFIX_PATH="${STONEFISH_INSTALL_PREFIX}:${CMAKE_PREFIX_PATH:-}"
export PKG_CONFIG_PATH="${STONEFISH_INSTALL_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="${STONEFISH_INSTALL_PREFIX}/lib:${LD_LIBRARY_PATH:-}"

log_step "Refreshing rosdep permissions"
sudo rosdep fix-permissions

log_step "Updating rosdep index"
rosdep update

log_step "Installing ROS dependencies"
sudo rosdep install \
    --from-paths "${ROSDEP_PATHS[@]}" \
    --ignore-src \
    --skip-keys "${SKIP_KEYS}" \
    -r \
    -y \
    --rosdistro "${ROS_DISTRO_VALUE}"

log_step "Building workspace with colcon"
colcon build \
    --symlink-install \
    --packages-select "${PACKAGES[@]}"
    # --event-handlers console_direct+

log_step "Build completed"
echo "Stonefish ROS 2 workspace built at ${STONEFISH_WS}."

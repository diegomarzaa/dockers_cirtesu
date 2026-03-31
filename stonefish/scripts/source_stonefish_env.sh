#!/usr/bin/env bash

ROS_DISTRO_VALUE="${ROS_DISTRO:-humble}"
CIRTESU_ROOT="${CIRTESU_ROOT:-/home/diego/Cirtesu}"
STONEFISH_WS="${STONEFISH_WS:-${CIRTESU_ROOT}/Simulations/stonefish_ws}"
STONEFISH_INSTALL_PREFIX="${STONEFISH_INSTALL_PREFIX:-${STONEFISH_WS}/stonefish_install}"

set +u
source "/opt/ros/${ROS_DISTRO_VALUE}/setup.bash"

if [ -d "${STONEFISH_INSTALL_PREFIX}" ]; then
    export CMAKE_PREFIX_PATH="${STONEFISH_INSTALL_PREFIX}:${CMAKE_PREFIX_PATH:-}"
    export PKG_CONFIG_PATH="${STONEFISH_INSTALL_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
    export LD_LIBRARY_PATH="${STONEFISH_INSTALL_PREFIX}/lib:${LD_LIBRARY_PATH:-}"
fi

if [ -f "${STONEFISH_WS}/install/setup.bash" ]; then
    source "${STONEFISH_WS}/install/setup.bash"
fi

set -u

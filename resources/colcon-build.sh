#!/usr/bin/env bash
# resources/colcon-build.sh — cobot2_ws 빌드 (step 10, reboot 후 마지막 빌드 단계).
#
# 핵심 (이정현이 실제로 겪은 dsr_msgs2 빌드 실패의 해법):
#   - config 가 기본 RMW 를 cyclonedds 로 고정하는데, ROS desktop 은 fastrtps 만 깐다.
#     → colcon 이 패키지의 기본 RMW 를 해석할 때 rmw_cyclonedds_cpp 가 없어 CMake 실패
#       ("Could not find ROS middleware implementation 'rmw_cyclonedds_cpp'").
#     → 빌드 "전에" cyclonedds RMW 패키지를 먼저 설치한다.
#   - rosdep 으로 워크스페이스 의존 자동 해소. 단 librealsense2 는 step 8 에서 native 로
#     깔았으므로 rosdep 이 또 건드리지 않게 skip.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./config.sh
source "${SCRIPT_DIR}/config.sh"
config_assert_set

# ROS 환경 로드 (set -u 회피하며 source).
set +u
source "/opt/ros/${ROS_DISTRO}/setup.bash"
set -u

# 1) === cyclonedds RMW 선설치 (dsr_msgs2 실패 패치) ===
# TODO(A): 빌드 전에 깔아야 할 RMW 패키지. (config 의 RMW 가 가리키는 그것)
#   [역할] ros-jazzy-rmw-??? — config 의 RMW_IMPLEMENTATION 이 rmw_cyclonedds_cpp 이니
#          그에 맞는 apt 패키지. dpkg 가드로 이미 있으면 skip (멱등 + 재개 시 네트워크 불요).
if ! dpkg -s "ros-${ROS_DISTRO}-rmw-cyclonedds-cpp" >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y "ros-${ROS_DISTRO}-rmw-cyclonedds-cpp"
fi

cd "${DSR_WORKSPACE}"

# 2) rosdep 으로 의존성 자동 해소.
# TODO(B): rosdep install 에서 "건드리지 말 키" 한 개. (step 8 에서 native 로 깐 것)
#   [역할] --skip-keys=??? — ROS rosdep 키가 아니라 native apt 로 깐 SDK.
rosdep update
rosdep install --from-paths src --ignore-src --rosdistro "${ROS_DISTRO}" \
    --skip-keys="librealsense2" -y

# 3) colcon 빌드 (증분 — build/install 안 지움, 재개 빠름).
# TODO(C): 워크스페이스를 빌드하는 명령. (ROS2 표준 빌드 도구)
#   [역할] ??? build — ament/cmake 패키지를 묶어 빌드하는 도구 이름.
colcon build

echo "colcon: cobot2_ws 빌드 완료 (source install/setup.bash 로 사용)"

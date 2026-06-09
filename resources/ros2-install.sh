#!/usr/bin/env bash
# resources/ros2-install.sh — ROS2 extras: 로봇/control 스택 + Gazebo (step 5).
#
# 22.04 원본의 jazzy 마이그레이션. 변경점:
#   - ros-humble-* → ros-${ROS_DISTRO}-* (distro 는 config 단일 소스).
#   - Gazebo: Classic(libignition-gazebo6, gazebo-ros-pkgs) 은 jazzy 빌드 없음(2025 EOL).
#     → Gazebo Harmonic 을 vendor 패키지 ros-${ROS_DISTRO}-ros-gz 로 설치.
#     원본의 OSRF 별도 apt repo + deprecated `apt-key add` 블록은 삭제.
#   - `apt upgrade -y` 제거 (drift).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./config.sh
source "${SCRIPT_DIR}/config.sh"
config_assert_set

sudo apt-get update

# 1) 기본 라이브러리 (DSR/robot 빌드 선행).
sudo apt-get install -y git libpoco-dev libyaml-cpp-dev dbus-x11

# 2) 로봇 / control 스택.
#    [역할 질문 C1] 아래 묶음의 역할은? → 로봇 관절을 "제어"하는 ros2_control 계열.
#    핵심 두 패키지의 뒷 단어를 맞혀보세요 (ros-jazzy-??? / ros-jazzy-???):
sudo apt-get install -y \
    "ros-${ROS_DISTRO}-control-msgs" \
    "ros-${ROS_DISTRO}-realtime-tools" \
    "ros-${ROS_DISTRO}-xacro" \
    "ros-${ROS_DISTRO}-joint-state-publisher-gui" \
    "ros-${ROS_DISTRO}-ros2-control" \
    "ros-${ROS_DISTRO}-ros2-controllers" \
    "ros-${ROS_DISTRO}-moveit-msgs"

# 3) lint / launch 유틸.
sudo apt-get install -y \
    "ros-${ROS_DISTRO}-ament-lint-common" \
    "ros-${ROS_DISTRO}-yaml-cpp-vendor" \
    "ros-${ROS_DISTRO}-ros2launch" \
    "ros-${ROS_DISTRO}-ament-pep257"

# 4) Gazebo Harmonic.
#    [역할 질문 G] 원본의 Gazebo Classic(별도 repo + apt-key)을 대체하는,
#    ROS 공식 vendor 메타패키지. ros-jazzy-??? 형태 한 개.
#    힌트: ros + gz(=gazebo) 를 합친 이름.
sudo apt-get install -y "ros-${ROS_DISTRO}-ros-gz"

echo "success installing ROS2 ${ROS_DISTRO} extras (control + Gazebo Harmonic)"

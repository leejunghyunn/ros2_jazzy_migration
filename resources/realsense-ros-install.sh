#!/usr/bin/env bash
# resources/realsense-ros-install.sh — RealSense ROS2 래퍼 (step 9, SDK 다음).
#
# step 8 SDK(librealsense2)가 카메라를 커널 레벨에서 잡으면,
# 이 래퍼가 그걸 /camera/camera/* ROS2 토픽으로 publish 한다 (SDK ← 래퍼 의존).
# 원본의 glob(ros-humble-realsense2-*) 대신 명시 패키지로 결정적 설치.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./config.sh
source "${SCRIPT_DIR}/config.sh"
config_assert_set

sudo apt-get update

# RealSense ROS2 래퍼 2종.
# TODO(A): 카메라를 토픽으로 publish 하는 "메인 래퍼 노드" 패키지.
#   [역할] ros-jazzy-realsense2-??? — 카메라 본체 (color/depth 토픽 발행).
# TODO(B): 로봇 모델에 카메라를 붙일 때 쓰는 "URDF/description" 패키지.
#   [역할] ros-jazzy-realsense2-??? — 카메라의 3D 모델/좌표 정의.
sudo apt-get install -y \
    "ros-${ROS_DISTRO}-realsense2-camera" \
    "ros-${ROS_DISTRO}-realsense2-description"

echo "realsense ROS2 래퍼 설치 완료 (SDK 위에서 /camera/camera/* 발행)"

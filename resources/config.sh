#!/usr/bin/env bash
# resources/config.sh — 모든 step이 공통으로 source 하는 설정 단일 진실 소스.
#
# 이 파일은 "무엇을 설치할지"가 아니라 "어떤 값으로 할지"만 정의한다.
# install.sh 와 모든 resources/*.sh 가 맨 처음 이 파일을 source 한다.
# 값을 바꿀 일이 생기면 여기 한 곳만 고치면 모든 step에 반영된다.

# --- OS / ROS 기준 -------------------------------------------------------
# 24.04 의 코드네임 (lsb_release -sc 출력값). apt source 줄에 그대로 들어감.
export UBUNTU_CODENAME="noble"
# 24.04 에 대응하는 ROS2 배포판 (소문자 — /opt/ros/jazzy, ros-jazzy-* 와 일치).
export ROS_DISTRO="jazzy"

# --- 워크스페이스 / 경로 -------------------------------------------------
# host colcon 워크스페이스 (Humble의 cobot_ws → jazzy는 cobot2_ws).
export DSR_WORKSPACE="${HOME}/cobot2_ws"
# 외부 repo 키링을 한 경로로 통일 (docker/ros/realsense/vscode 가 공유).
export KEYRING_DIR="/etc/apt/keyrings"
# state / 머신 종속 산출물(cyclonedds.xml 등) 저장 디렉토리.
export STATE_DIR="${HOME}/.ros2_jazzy_test"
export STATE_FILE="${STATE_DIR}/state"

# --- 커널 (HWE 메타 — nvidia/realsense DKMS 선행) ------------------------
# noble HWE 이미지 메타 + 헤더 메타. DKMS 모듈 빌드에 헤더가 필요하다.
export KERNEL_META="linux-generic-hwe-24.04"
export KERNEL_HEADERS_META="linux-headers-generic-hwe-24.04"

# --- NVIDIA 드라이버 -----------------------------------------------------
# 선임이 검증한 버전 (RTX 4060, 검은화면 회피). 숫자만 — 스크립트가 조립.
# 빈 값이면 ubuntu-drivers 자동선택(비결정적)으로 폴백.
export NVIDIA_DRIVER_VERSION="595"
# closed 변형 핀 (open 커널모듈 쓰려면 "-open").
export NVIDIA_DRIVER_FLAVOR=""

# --- Doosan DSR ----------------------------------------------------------
# git clone -b 뒤에 올 브랜치명 (doosan-robot2 의 jazzy 브랜치).
export DSR_BRANCH="jazzy"
# 에뮬레이터 이미지 태그 (latest 금지 — 명시 핀).
export DSR_EMULATOR_VERSION="3.0.1"

# --- DDS / RMW (host ↔ 컨테이너 동일해야 discovery 성립) -----------------
# 프로젝트 표준 RMW. CycloneDDS = XML로 버퍼/NIC 명시 제어 → RealSense 대용량
# 토픽 결정적 튜닝 가능 (FastDDS 와 혼합 시 같은 topic 도 안 보임).
export RMW_IMPLEMENTATION="${RMW_IMPLEMENTATION:-rmw_cyclonedds_cpp}"
: "${CYCLONEDDS_XML:=${STATE_DIR}/cyclonedds.xml}"
export CYCLONEDDS_URI="${CYCLONEDDS_URI:-file://${CYCLONEDDS_XML}}"
: "${DDS_NETIF:=}"
# host + 두 컨테이너가 공유할 도메인 ID. 셋 다 동일해야 discovery 성립.
# 선임 레포 기준 42. (조별 번호로 99 등 다른 값도 가능 — 단, 전부 통일 필수.)
export ROS_DOMAIN_ID="${ROS_DOMAIN_ID:-42}"

# --- 진행률 --------------------------------------------------------------
# 전체 step 수 = a01:6 + a02:4 + a03:1 + a04:1 + dds-tuning:1 = 13.
# (reboot 는 a01 의 step 6 에 포함 — 따로 세지 않음.)
: "${TOTAL_STEPS:=13}"

# --- Self-check (자식 스크립트가 진입 직후 호출) -------------------------
config_assert_set() {
    local var missing=0
    for var in ROS_DISTRO UBUNTU_CODENAME STATE_FILE KEYRING_DIR \
               KERNEL_META KERNEL_HEADERS_META DSR_WORKSPACE \
               RMW_IMPLEMENTATION CYCLONEDDS_XML; do
        if [[ -z "${!var:-}" ]]; then
            echo "config: required variable '$var' is empty" >&2
            missing=1
        fi
    done
    return "${missing}"
}

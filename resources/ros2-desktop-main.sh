#!/usr/bin/env bash
# resources/ros2-desktop-main.sh — ROS2 jazzy desktop 코어 설치 (step 4).
#
# 22.04 원본(Tiryoh 기반)의 jazzy/noble 마이그레이션. 변경점:
#   - distro/OS 를 config.sh 단일 소스에서 (${ROS_DISTRO}/${UBUNTU_CODENAME}).
#   - apt key 를 /etc/apt/keyrings 로 통일 (docker 와 같은 경로).
#   - `apt upgrade -y` 제거 (핀 drift 원인).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./config.sh
source "${SCRIPT_DIR}/config.sh"
config_assert_set

ROS_KEY="${KEYRING_DIR}/ros.gpg"
ROS_LIST=/etc/apt/sources.list.d/ros2.list

# --- OS 검증 -------------------------------------------------------------
if ! command -v lsb_release >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y curl lsb-release
fi

# TODO(A): 현재 OS 코드네임이 config 의 대상 코드네임과 "다르면" 중단.
#   [역할 질문] 빈칸 ①에는 무엇과 비교할 값(config 변수)이?
#              빈칸 ②에는 "다를 때" 할 행동(명령)이?
if [[ "$(lsb_release -sc)" == "${UBUNTU_CODENAME}" ]]; then
    echo "OS Check Passed (${UBUNTU_CODENAME})"
else
    echo "ERROR: This OS ($(lsb_release -sc)) != ${UBUNTU_CODENAME}" >&2
    exit 1
fi

# --- keyring → source → install (docker 와 동일 패턴) --------------------
sudo apt-get update
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y universe
sudo apt-get install -y curl gnupg2 lsb-release build-essential

# 2) ROS GPG 키 (없을 때만 — idempotent).
sudo install -m 0755 -d "${KEYRING_DIR}"
if [[ ! -f "${ROS_KEY}" ]]; then
    sudo curl -fsSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o "${ROS_KEY}"
    sudo chmod a+r "${ROS_KEY}"
fi

# 3) apt source.
# TODO(B): source 줄의 코드네임 자리. (docker 에서 본 그 자리 — 같은 역할)
arch="$(dpkg --print-architecture)"
desired="deb [arch=${arch} signed-by=${ROS_KEY}] http://packages.ros.org/ros2/ubuntu ${UBUNTU_CODENAME} main"
if ! { [[ -f "${ROS_LIST}" ]] && grep -qxF "${desired}" "${ROS_LIST}"; }; then
    echo "${desired}" | sudo tee "${ROS_LIST}" >/dev/null
fi
sudo apt-get update

# --- ROS2 desktop + dev 도구 --------------------------------------------
# TODO(C): 설치할 메인 패키지. (역할: ROS2 의 "desktop" 풀세트)
#   [역할 질문] ros-<distro>-??? 형태. distro 는 ${ROS_DISTRO}, 뒤 단어는?
sudo apt-get install -y "ros-${ROS_DISTRO}-ament-package" python3-pyqt5 "ros-${ROS_DISTRO}-ament-cmake" libzmq3-dev
sudo apt-get install -y "ros-${ROS_DISTRO}-desktop"
sudo apt-get install -y python3-argcomplete python3-colcon-clean python3-colcon-common-extensions
sudo apt-get install -y python3-rosdep python3-vcstool

# --- rosdep (init 1회만) -------------------------------------------------
# TODO(D): rosdep 을 "한 번만" init 하려고 조건을 건다.
#   [역할 질문] 빈칸엔 "init 이 이미 됐는지" 보여주는 파일 존재 검사. 핵심은 init 을
#              매번 하면 에러가 난다는 것 — 그래서 "없을 때만" 한다.
if [[ ! -e /etc/ros/rosdep/sources.list.d/20-default.list ]]; then
    sudo rosdep init
fi
rosdep update

# --- ~/.bashrc 자동 source (중복 방지 grep 가드) ------------------------
# TODO(E): jazzy setup.bash 를 .bashrc 에 추가하되, "이미 있으면 추가 안 함".
#   [역할 질문] grep -qF "..." 가 "이미 있나" 검사. 없을 때만(||) echo 로 추가.
bashrc="${HOME}/.bashrc"
grep -qF "source /opt/ros/${ROS_DISTRO}/setup.bash" "${bashrc}" \
    || echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> "${bashrc}"

echo "success installing ROS2 ${ROS_DISTRO}"

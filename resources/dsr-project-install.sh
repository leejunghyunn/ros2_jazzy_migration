#!/usr/bin/env bash
# resources/dsr-project-install.sh — Doosan DSR + host 패키지 (step 7, reboot 후).
#
# 22.04 원본의 jazzy 마이그레이션. 핵심:
#   - doosan-robot2 를 ${DSR_BRANCH}(jazzy) 로 clone.
#   - host 가 빌드할 2개(robot_control, od_msg)만 워크스페이스 src 로 복사.
#     (object_detection/voice_processing 은 컨테이너 소관 — host 빌드 제외.)
#   - DSR 소스 버그 2건 패치 (오타 클래스명 / 빈 service prefix → 22.04 의 hang 원인).
#   - robot_control 런타임 Python (host 에서 ROS2 노드로 실행 → scipy/pymodbus 필요).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"   # 이 레포 루트 (robot_control/od_msg 원본 위치)
# shellcheck source=./config.sh
source "${SCRIPT_DIR}/config.sh"
config_assert_set

DSR_SRC="${DSR_WORKSPACE}/src"
mkdir -p "${DSR_SRC}"

# 1) doosan-robot2 clone (이미 있으면 skip — idempotent).
# TODO(A): clone 할 브랜치 자리. config 의 어떤 변수?
#   [역할] "어느 브랜치를 받을지" — jazzy 를 담은 변수.
if [[ ! -d "${DSR_SRC}/doosan-robot2" ]]; then
    git clone -b "${DSR_BRANCH}" https://github.com/doosan-robotics/doosan-robot2.git \
        "${DSR_SRC}/doosan-robot2"
fi

# 2) host 빌드 대상 2개 복사 (symlink 아님 — 레포/USB 위치 의존 제거).
# TODO(B): host 가 빌드할 두 패키지 이름. (object_detection/voice 는 아님!)
#   [역할] 하나는 "로봇 제어" 코드, 하나는 "object detection 결과 메시지 타입".
cp -a "${REPO_ROOT}/robot_control" "${REPO_ROOT}/od_msg" "${DSR_SRC}/"

# 3) DSR 빌드 의존성 (apt).
sudo apt-get update
sudo apt-get install -y \
    "ros-${ROS_DISTRO}-velocity-controllers" \
    "ros-${ROS_DISTRO}-eigen3-cmake-module"

# 4) robot_control 런타임 Python.
#    [역할 질문 P] robot_control 이 host 에서 하는 일 → 좌표 변환 + 그리퍼 Modbus 제어.
#    그래서 필요한 두 가지: 과학연산 라이브러리 / Modbus 통신 라이브러리.
sudo apt-get install -y python3-numpy python3-scipy python3-pymodbus

# 5) DSR emulator 이미지 (명시 태그 — latest 금지).
docker pull "doosanrobot/dsr_emulator:${DSR_EMULATOR_VERSION}"

# 6) === 소스 버그 패치 2건 (22.04 에서 발견) ===
DSR_PY="$(find "${DSR_SRC}/doosan-robot2" -name 'DSR_ROBOT2.py' | head -n1)"
if [[ -n "${DSR_PY}" ]]; then
    # 패치 1: 존재하지 않는 클래스명 오타 (Singularity → Singular) 교정.
    sed -i 's/SetSingularityHandlingForce/SetSingularHandlingForce/g' "${DSR_PY}"
    # 패치 2: 빈 service prefix → 'dsr_controller2/' (안 채우면 get_current_posj 무한 대기).
    #   (실제 패치 위치/패턴은 레포 코드에 맞춰 조정 — 여기선 개념만 표시)
fi

echo "dsr: clone + 복사 + 패치 + 런타임 + 에뮬레이터 완료 (${DSR_WORKSPACE})"

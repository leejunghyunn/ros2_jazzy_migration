#!/usr/bin/env bash
# resources/nvidia-driver-install.sh — NVIDIA GPU 드라이버 (step 2, 커널 다음).
#
# 정책:
#   - NVIDIA_DRIVER_VERSION 핀 설치 (자동선택은 검은 화면 유발 → 검증본 재현).
#   - 드라이버 userspace 만 apt-mark hold (apt upgrade 메이저 drift 차단).
#     커널-모듈 메타는 hold 안 함 — hold 하면 커널 추적이 끊겨 다음 커널에서 모듈이 빠진다.
#   - 재부팅 전 검증 게이트: 부팅 예정 커널에 nvidia.ko 가 실제로 있는지 확인,
#     없으면 exit 1 — 검은 화면 brick 을 재부팅 전에 차단.
#   - reboot 는 여기서 안 함 (a01 의 reboot step 이 confirm 후 처리).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./config.sh
source "${SCRIPT_DIR}/config.sh"
config_assert_set

# apt component 활성화 (nvidia-modprobe 가 multiverse 소속).
sudo apt-get update
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y universe
sudo add-apt-repository -y multiverse

# 빌드 도구 + DKMS.
sudo apt-get update
sudo apt-get install -y build-essential gcc ubuntu-drivers-common dkms nvidia-modprobe

# --- 드라이버 핀 설치 ----------------------------------------------------
# 드라이버 패키지명 = nvidia-driver-<버전><변형>  (예: nvidia-driver-595)
# 커널 모듈 메타   = linux-modules-nvidia-<버전><변형>-<HWE커널>
pin_pkg="nvidia-driver-${NVIDIA_DRIVER_VERSION}${NVIDIA_DRIVER_FLAVOR}"
module_meta="linux-modules-nvidia-${NVIDIA_DRIVER_VERSION}${NVIDIA_DRIVER_FLAVOR}-${KERNEL_META#linux-}"

# TODO(1): pin_pkg 와 module_meta 두 패키지를 함께 설치하라.
#   힌트: 둘 다 apt-get install. 변수 참조는 "${...}".
#         sudo apt-get install -y "${pin_pkg}" "${module_meta}"
sudo apt-get install -y "${pin_pkg}" "${module_meta}"

# --- drift 차단: 드라이버 userspace 만 hold ------------------------------
# TODO(2): pin_pkg 를 apt-mark hold 하라 (module_meta 는 hold 하지 않는다!).
#   힌트: sudo apt-mark hold "${pin_pkg}"
#   질문: 왜 module_meta 는 hold 하면 안 될까? (주석 맨 위 참고)
sudo apt-mark hold "${pin_pkg}"
echo "nvidia: installed & held -> ${pin_pkg}"

# --- 재부팅 전 검증 게이트 -----------------------------------------------
# 부팅 예정 커널(= 설치된 것 중 최신 버전)에 nvidia.ko 가 있는지 확인.
# $(uname -r) 는 재부팅 전엔 구 커널일 수 있으므로, /lib/modules 의 최신 버전 디렉토리를 본다.
target_kernel="$(find /lib/modules -mindepth 1 -maxdepth 1 -type d -printf '%f\n' \
                 | grep -E '^[0-9]+\.' | sort -V | tail -n1)"

# TODO(3): target_kernel 모듈 트리에 nvidia.ko* 파일이 "있으면" 검증 OK,
#          "없으면" 경고 출력하고 exit 1 (검은 화면 차단).
#   힌트: find "/lib/modules/${target_kernel}" -name 'nvidia.ko*' | grep -q .
#         → 있으면 grep 이 0(성공) 반환. if ...; then OK; else 경고+exit 1; fi
if find "/lib/modules/${target_kernel}" -name 'nvidia.ko*' 2>/dev/null | grep -q .; then
    echo "nvidia: 검증 OK — 부팅 예정 커널(${target_kernel})에 nvidia.ko 존재."
else
    echo "nvidia: 검증 실패 — ${target_kernel} 에 nvidia.ko 부재. 재부팅 시 검은 화면 위험." >&2
    # TODO(4): 여기서 스크립트를 중단하라 (검은 화면 brick 방지).
    #   힌트: 비0 코드로 종료하는 명령 한 단어.
    exit 1
fi

#!/usr/bin/env bash
# resources/realsense-sdk-install.sh — RealSense SDK librealsense2 (step 8, reboot 후).
#
# 22.04 와 결정적 차이 (NO_PUBKEY 의 진짜 원인):
#   - 2025-11 Intel 이 RealSense 를 분사 → apt repo 도메인/GPG 키가 바뀜.
#     구 Intel 키(librealsense.intel.com)로는 새 noble repo 검증 실패(NO_PUBKEY).
#   - 그래서: 구 Intel 키/소스 먼저 제거 → 새 realsenseai.com 키/소스 등록.
#   - librealsense2-dkms 는 커널 모듈 → DKMS 빌드에 커널 헤더 필요(step 1 에서 보장).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./config.sh
source "${SCRIPT_DIR}/config.sh"
config_assert_set

RS_KEY="${KEYRING_DIR}/librealsenseai.gpg"
RS_LIST=/etc/apt/sources.list.d/librealsenseai.list

# 0) 구 Intel 잔재 제거 (분사 전 키/소스 — 남아있으면 NO_PUBKEY 로 update 실패).
sudo rm -f /etc/apt/keyrings/librealsense.pgp \
           /etc/apt/sources.list.d/librealsense.list \
           /usr/share/keyrings/librealsense.pgp 2>/dev/null || true

# 1) 선행 도구 + DKMS 헤더.
# TODO(A): DKMS 커널 모듈 빌드에 필요한 것 → "커널 헤더". config 의 어떤 변수?
#   [역할] step 1 에서 깐 HWE 헤더 메타 + 현재 커널 헤더.
sudo apt-get install -y curl ca-certificates gnupg apt-transport-https \
    "${KERNEL_HEADERS_META}" "linux-headers-$(uname -r)"

# 2) 새 GPG 키 (realsenseai.com — 없을 때만).
sudo install -m 0755 -d "${KEYRING_DIR}"
if [[ ! -f "${RS_KEY}" ]]; then
    curl -sSf https://librealsense.realsenseai.com/Debian/librealsenseai.asc \
        | gpg --dearmor | sudo tee "${RS_KEY}" >/dev/null
    sudo chmod a+r "${RS_KEY}"
fi

# 3) apt source.
# TODO(B): source 줄의 코드네임 자리. (docker/ros2 에서 본 그 자리 — 같은 역할)
desired="deb [signed-by=${RS_KEY}] https://librealsense.realsenseai.com/Debian/apt-repo ${UBUNTU_CODENAME} main"
if ! { [[ -f "${RS_LIST}" ]] && grep -qxF "${desired}" "${RS_LIST}"; }; then
    echo "${desired}" | sudo tee "${RS_LIST}" >/dev/null
fi
sudo apt-get update

# 4) SDK 패키지 4종.
# TODO(C): 이 중 "커널 모듈"을 만드는 DKMS 패키지는? (나머지는 utils/dev/dbg)
#   [역할] 카메라를 커널 레벨에서 잡는 모듈 = librealsense2-???
sudo apt-get install -y \
    "librealsense2-dkms" \
    librealsense2-utils \
    librealsense2-dev \
    librealsense2-dbg

echo "realsense SDK: 설치 완료 (dkms status 로 모듈 확인 권장)"

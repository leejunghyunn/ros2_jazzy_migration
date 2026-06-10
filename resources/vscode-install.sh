#!/usr/bin/env bash
# resources/vscode-install.sh — VS Code 설치 (step 11, 개발 도구).
#
# keyring → source → install 패턴 (docker/ros2/realsense 와 동일 구조 — 4번째 반복).
# 22.04 원본은 .deb 직접 받아 dpkg -i 했지만, repo 등록 방식이 업데이트 추적에 유리.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./config.sh
source "${SCRIPT_DIR}/config.sh"
config_assert_set

MS_KEY="${KEYRING_DIR}/packages.microsoft.gpg"
VSCODE_LIST=/etc/apt/sources.list.d/vscode.list

# 1) 선행 도구.
sudo apt-get install -y wget gpg apt-transport-https ca-certificates

# 2) Microsoft GPG 키 (없을 때만 — idempotent).
sudo install -m 0755 -d "${KEYRING_DIR}"
if [[ ! -f "${MS_KEY}" ]]; then
    # TODO(A): MS 키를 받아 gpg --dearmor 로 변환해 ${MS_KEY} 에 저장.
    #   [역할] realsense 에서 본 그 패턴 (curl|gpg --dearmor|tee). 키 URL 은 채워둠.
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor | sudo tee "${MS_KEY}" >/dev/null
    sudo chmod a+r "${MS_KEY}"
fi

# 3) apt source.
#   [역할] vscode repo 는 OS 코드네임을 안 쓴다 (stable main 고정). 그대로 둠.
arch="$(dpkg --print-architecture)"
desired="deb [arch=${arch} signed-by=${MS_KEY}] https://packages.microsoft.com/repos/code stable main"
if ! { [[ -f "${VSCODE_LIST}" ]] && grep -qxF "${desired}" "${VSCODE_LIST}"; }; then
    echo "${desired}" | sudo tee "${VSCODE_LIST}" >/dev/null
fi
sudo apt-get update

# 4) VS Code 설치.
# TODO(B): VS Code 의 apt 패키지 이름. (한 단어 — 22.04 원본의 dpkg -i 대상과 동일 패키지)
#   [역할] "code 에디터" 패키지.
sudo apt-get install -y code

echo "vscode: 설치 완료 ($(code --version 2>/dev/null | head -n1 || echo 'code'))"

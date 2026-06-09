#!/usr/bin/env bash
# resources/docker-install.sh — Docker CE 설치 (step 3).
#
# 정책:
#   - noble 용 latest stable docker-ce 스택 설치 (버전 핀 없음 — nvidia 와 다른 전략).
#   - 설치 후 apt-mark hold 로 엔진 잠금 (apt upgrade drift 차단).
#   - docker 그룹에 현재 사용자 추가 (sudo 없이 실행). 적용은 재부팅/재로그인 후.
#   keyring → source → install 패턴 (이후 ros2/realsense/vscode 도 동일 구조).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./config.sh
source "${SCRIPT_DIR}/config.sh"
config_assert_set

DOCKER_LIST=/etc/apt/sources.list.d/docker.list
DOCKER_KEY="${KEYRING_DIR}/docker.asc"

# 1) 선행 도구.
sudo apt-get update
sudo apt-get install -y ca-certificates curl

# 2) GPG 키 내려받기 (이미 있으면 skip — idempotent).
sudo install -m 0755 -d "${KEYRING_DIR}"
if [[ ! -f "${DOCKER_KEY}" ]]; then
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o "${DOCKER_KEY}"
    sudo chmod a+r "${DOCKER_KEY}"
fi

# 3) apt source 등록 (동일 내용이면 재기록 안 함 — 중복 방지).
arch="$(dpkg --print-architecture)"
# TODO(1): apt source 줄에서 OS 코드네임 자리에 config 의 변수를 넣어라.
#   힌트: 원본은 $(. /etc/os-release && echo "$VERSION_CODENAME") 로 jammy 를 뽑았지만,
#         우리는 config.sh 단일 소스를 쓴다. noble 을 담은 변수는?
desired="deb [arch=${arch} signed-by=${DOCKER_KEY}] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable"
if ! { [[ -f "${DOCKER_LIST}" ]] && grep -qxF "${desired}" "${DOCKER_LIST}"; }; then
    echo "${desired}" | sudo tee "${DOCKER_LIST}" >/dev/null
fi

# 4) 엔진 설치 (latest stable — 버전 핀 없음).
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 5) 엔진 패키지 hold (drift 차단 — 이미 hold 면 skip).
for pkg in docker-ce docker-ce-cli containerd.io; do
    if apt-mark showhold | grep -qx "${pkg}"; then
        echo "docker: ${pkg} 이미 hold 됨"
    else
        # TODO(2): pkg 를 hold 하라.
        #   힌트: sudo apt-mark hold "${pkg}"
        sudo apt-mark hold "${pkg}"
    fi
done

# 6) 현재 사용자를 docker 그룹에 추가 (적용은 재부팅/재로그인 후).
user="$(id -un)"
if id -nG "${user}" | tr ' ' '\n' | grep -qx docker; then
    echo "docker: ${user} 이미 docker 그룹"
else
    # TODO(3): user 를 docker 그룹에 추가하라 (sudo 없이 docker 쓰게).
    #   힌트: 원본과 동일. sudo usermod -aG docker "${user}"
    sudo usermod -aG docker "${user}"
    echo "docker: ${user} 를 docker 그룹에 추가 (적용은 재부팅 후)"
fi

# 7) 검증 — 그룹 변경이 현재 셸엔 미적용이라 sudo 로 실행. --rm 으로 정리.
# TODO(4): hello-world 컨테이너를 실행해 동작 검증하라.
#   힌트: sudo docker run --rm hello-world
sudo docker run --rm hello-world

echo "docker: installed & held"
docker --version

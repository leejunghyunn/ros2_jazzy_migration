#!/usr/bin/env bash
# resources/voice-env-check.sh — 음성 자격증명 점검 (step 12, host 설치 없음).
#
# Humble 과 핵심 차이: 음성 패키지(langchain/openai/pyaudio/openwakeword)를 host 에
# 설치하지 않는다. 전부 voice 컨테이너(Dockerfile.voice) 소관. host 는 컨테이너가
# 쓸 자격증명만 점검: .env(OPENAI_API_KEY) + Docker Hub 로그인.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=./config.sh
source "${SCRIPT_DIR}/config.sh"
config_assert_set

ENV_FILE="${REPO_ROOT}/.env"

# 1) .env 보장 — 없으면 예시에서 생성 (권한 600 — 키 파일이라 소유자만).
if [[ ! -f "${ENV_FILE}" ]]; then
    if [[ -f "${REPO_ROOT}/.env.example" ]]; then
        cp "${REPO_ROOT}/.env.example" "${ENV_FILE}"
    else
        : > "${ENV_FILE}"
    fi
    chmod 600 "${ENV_FILE}"
fi

# 2) OPENAI_API_KEY 확보.
#    이미 .env 에 채워져 있으면 skip. 비어 있고 대화형이면 입력받아 기록.
if grep -q '^OPENAI_API_KEY=.\+' "${ENV_FILE}"; then
    echo "voice: OPENAI_API_KEY 이미 설정됨"
elif [[ -t 0 ]]; then
    # TODO(A): 키를 입력받되 "화면에 안 보이게" 받아라.
    #   [역할] confirm.sh 의 read 변형 — 비밀번호처럼 echo 안 되는 옵션.
    #   힌트: read 에 -s 플래그 (silent). read ___ -p "OpenAI API Key: " key
    read -s -p "OpenAI API Key 입력: " key
    echo ""
    # .env 에 기록 (기존 줄 있으면 교체, 없으면 추가 — state.sh 와 같은 멱등 패턴).
    if grep -q '^OPENAI_API_KEY=' "${ENV_FILE}"; then
        sed -i "s|^OPENAI_API_KEY=.*|OPENAI_API_KEY=${key}|" "${ENV_FILE}"
    else
        echo "OPENAI_API_KEY=${key}" >> "${ENV_FILE}"
    fi
    echo "voice: OPENAI_API_KEY 기록 완료 (.env, 화면 미출력)"
else
    echo "voice: 경고 — OPENAI_API_KEY 미설정 + 비대화형. 나중에 .env 직접 채우세요." >&2
fi

# 3) Docker Hub 로그인 점검 (이미지 pull/push 용 — 안내만, 강제 안 함).
# TODO(B): docker 로그인 여부를 확인하는 자리. (config.json 의 auths 항목 존재 여부)
#   [역할] 로그인돼 있으면 통과, 아니면 "docker login 하라"고 안내만.
if [[ -f "${HOME}/.docker/config.json" ]] && grep -q '"auths"' "${HOME}/.docker/config.json"; then
    echo "voice: Docker Hub 로그인 확인됨"
else
    echo "voice: (안내) 'docker login' 필요할 수 있음 — 이미지 pull/push 시."
fi

echo "voice-env-check: 자격증명 점검 완료 (음성 패키지는 voice 컨테이너 소관)"

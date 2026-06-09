#!/usr/bin/env bash
# resources/state.sh — Step 진행 추적 (resumable 재실행 + [n/total] 진행률).
#
# State file format (key=value — grep/sed 기반 in-place 갱신으로 idempotent):
#   step_<name>=DONE|FAIL|SKIPPED|RUNNING
#
# config.sh 가 STATE_FILE 을 정의한다. install.sh 가 이 파일을 source 한다.

# state 파일 보장 — 없으면 빈 파일 생성 (디렉토리까지).
state_init() {
    mkdir -p "$(dirname "${STATE_FILE}")"
    [[ -f "${STATE_FILE}" ]] || : > "${STATE_FILE}"
}

# ---------------------------------------------------------------------------
# state_get <name> — step_<name> 의 현재 상태를 stdout 으로 출력.
#   없으면 빈 문자열. (예: state_get a01_nvidia → "DONE")
# ---------------------------------------------------------------------------
state_get() {
    local name="$1"
    grep "^step_${name}=" "${STATE_FILE}" 2>/dev/null | cut -d= -f2 || true
}

# ---------------------------------------------------------------------------
# state_set <name> <status> — step_<name>=<status> 로 기록 (멱등).
#   이미 있으면 그 줄을 교체(append 아님 — 중복 방지), 없으면 추가.
# ---------------------------------------------------------------------------
state_set() {
    local name="$1" status="$2"
    state_init
    if grep -q "^step_${name}=" "${STATE_FILE}"; then
        sed -i "s|^step_${name}=.*|step_${name}=${status}|" "${STATE_FILE}"
    else
        echo "step_${name}=${status}" >> "${STATE_FILE}"
    fi
}

# state_is_done <name> — DONE 이면 exit 0, 아니면 1 (run-step 이 skip 판단에 사용).
state_is_done() {
    [[ "$(state_get "$1")" == "DONE" ]]
}

# state_reset — 전체 초기화 (install.sh --reset 에서 confirm 후 호출).
state_reset() {
    : > "${STATE_FILE}"
    echo "state: 초기화 완료 (${STATE_FILE})"
}

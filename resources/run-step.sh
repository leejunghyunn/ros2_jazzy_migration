#!/usr/bin/env bash
# resources/run-step.sh — step 실행 래퍼 (state 기반 skip/기록 + 진행률).
#
# config.sh + state.sh 를 엮는다. install.sh 가 각 step 을 이걸로 감싼다:
#   run_step 2 a01_nvidia bash "${RESOURCE_DIR}/nvidia-driver-install.sh"
#
# 설치 본문 스크립트는 state 를 직접 안 건드린다 — 프레이밍은 여기가 소유.

# ---------------------------------------------------------------------------
# run_step <번호> <이름> <명령...> — 한 step 을 state 로 감싸 실행.
# ---------------------------------------------------------------------------
run_step() {
    local num="$1" name="$2"
    shift 2                      # 앞 2개(번호·이름) 떼어내고, 남은 건 실행할 명령
    local total="${TOTAL_STEPS:-13}"

    # 1) 진행률 표시.
    echo ""
    echo "===== [${num}/${total}] ${name} ====="

    # 2) 이미 끝났으면 건너뛰기.
    # TODO(1): 이 step 이 이미 DONE 이면 "skip" 출력하고 return 0.
    #   힌트: state.sh 에 만든 "끝났는지 판정하는 함수"를 쓰면 된다.
    #         if state_is_done "${name}"; then echo "  → 이미 완료, skip"; return 0; fi
    if state_is_done "${name}"; then
        echo "  → 이미 완료됨, 건너뜀"
        return 0
    fi

    # 3) 명령 실행 ("$@" = 번호·이름 뗀 나머지 = 실제 명령).
    if "$@"; then
        # 4a) 성공 → DONE 기록.
        # TODO(2): 이 step 을 DONE 으로 기록하라.
        #   힌트: state.sh 의 "상태 기록 함수" 사용. ____ "${name}" DONE
        state_set "${name}" DONE
        echo "  → [OK] ${name}"
        return 0
    else
        # 4b) 실패 → FAIL 기록하고 비0 반환 (install.sh 가 여기서 멈춤).
        state_set "${name}" FAIL
        echo "  → [FAIL] ${name}" >&2
        return 1
    fi
}

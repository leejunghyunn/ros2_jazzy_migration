#!/usr/bin/env bash
# resources/confirm.sh — 되돌릴 수 없는 작업 전 사용자 동의 프롬프트.
# (sudo reboot / apt purge / driver swap / state reset 등 명시 동의 필수).
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/confirm.sh"
#   confirm_or_abort "지금 재부팅할까요?"   # y 면 통과, 아니면 exit 1

# ---------------------------------------------------------------------------
# confirm_or_abort <메시지> — 메시지를 보여주고 y/Y 면 0(통과), 아니면 비0(중단).
# ---------------------------------------------------------------------------
confirm_or_abort() {
    local prompt="$1"

    # 비대화형(파이프/CI 등 입력 불가)일 땐 물어볼 수 없으니 안전하게 중단.
    if [[ ! -t 0 ]]; then
        echo "confirm: 비대화형 실행 — '${prompt}' 자동 동의 불가, 중단." >&2
        return 1
    fi

    # 사용자에게 묻기 (줄바꿈 없이 같은 줄에 입력받도록 printf 사용).
    printf '%s [y/N]: ' "${prompt}"

    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

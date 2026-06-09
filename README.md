# my_ros2_jazzy
Ubuntu 22.04 Humble → 24.04 Jazzy 마이그레이션 (학습용 직접 구현).

## 구조
- `install.sh` — 단일 진입점 (13 step, state 기반 재개)
- `resources/` — 설치 본문 + 공통 인프라(config/state/confirm/run-step)
- `a01~a04` — step 묶음 오케스트레이터

## 진행 상황
- [x] resources/config.sh — 설정 단일 소스
- [ ] resources/state.sh
- [ ] resources/confirm.sh
- [ ] ... (작성 중)


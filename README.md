# ros2_jazzy_migration

Ubuntu 22.04 Humble → 24.04 Jazzy 마이그레이션 (학습용 직접 구현).

## 구조

```
ros2_jazzy_migration/
├── install.sh          # 단일 진입점 (13 step, state 기반 재개)
├── resources/
│   ├── config.sh       # 설정 단일 소스 (경로·버전·환경변수)
│   ├── state.sh        # step 진행 추적 (DONE/FAIL/SKIPPED/RUNNING)
│   ├── confirm.sh      # 되돌릴 수 없는 작업 전 사용자 동의 프롬프트
│   └── run-step.sh     # step 실행 래퍼 (state 기반 skip + 진행률)
└── a01~a04/            # step 묶음 오케스트레이터
```

## 진행 상황

### resources/ 공통 인프라
- [x] `config.sh` — 설정 단일 소스 (ROS_DISTRO, 경로, NVIDIA, DDS 등)
- [x] `state.sh` — step 상태 기록/조회/초기화 (멱등, grep/sed 기반)
- [x] `confirm.sh` — 비대화형 환경 자동 중단 포함 y/N 프롬프트
- [x] `run-step.sh` — `[n/total]` 진행률, DONE skip, FAIL 기록

### 설치 step (작성 중)
- [ ] a01 — 커널 HWE + NVIDIA 드라이버
- [ ] a02 — ROS 2 Jazzy 설치
- [ ] a03 — Doosan DSR 워크스페이스 빌드
- [ ] a04 — DDS / CycloneDDS 설정

## 환경
- OS: Ubuntu 24.04 (noble)
- ROS: ROS 2 Jazzy
- RMW: CycloneDDS (`rmw_cyclonedds_cpp`)


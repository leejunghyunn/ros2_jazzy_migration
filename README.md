# ros2_jazzy_migration

Ubuntu 22.04 Humble → 24.04 Jazzy 마이그레이션

## 구조

```
ros2_jazzy_migration/
├── install.sh                   # 단일 진입점 (13 step, state 기반 재개)
└── resources/
    ├── config.sh                # 설정 단일 소스 (경로·버전·환경변수)
    ├── state.sh                 # step 진행 추적 (DONE/FAIL/SKIPPED/RUNNING)
    ├── confirm.sh               # 되돌릴 수 없는 작업 전 사용자 동의 프롬프트
    ├── run-step.sh              # step 실행 래퍼 (state 기반 skip + 진행률)
    ├── kernel-baseline.sh       # step 1 — HWE 커널 베이스라인 보장
    ├── nvidia-driver-install.sh # step 2 — NVIDIA GPU 드라이버 설치
    ├── docker-install.sh        # step 3 — Docker CE 설치
    ├── ros2-desktop-main.sh     # step 4 — ROS 2 Jazzy desktop 코어 설치
    └── ros2-install.sh          # step 5 — ROS 2 extras (로봇/control + Gazebo)
```

## 진행 상황

### resources/ 공통 인프라
- [x] `config.sh` — 설정 단일 소스 (ROS_DISTRO, 경로, NVIDIA, DDS 등)
- [x] `state.sh` — step 상태 기록/조회/초기화 (멱등, grep/sed 기반)
- [x] `confirm.sh` — 비대화형 환경 자동 중단 포함 y/N 프롬프트
- [x] `run-step.sh` — `[n/total]` 진행률, DONE skip, FAIL 기록

### 설치 step
- [x] step 1 — `kernel-baseline.sh` — HWE 커널 베이스라인 보장
- [x] step 2 — `nvidia-driver-install.sh` — NVIDIA GPU 드라이버
- [x] step 3 — `docker-install.sh` — Docker CE
- [x] step 4 — `ros2-desktop-main.sh` — ROS 2 Jazzy desktop 코어
- [x] step 5 — `ros2-install.sh` — ROS 2 extras (로봇/control 스택 + Gazebo)
- [ ] step 6~13 — 작성 중

## 환경
- OS: Ubuntu 24.04 (noble)
- ROS: ROS 2 Jazzy
- RMW: CycloneDDS (`rmw_cyclonedds_cpp`)


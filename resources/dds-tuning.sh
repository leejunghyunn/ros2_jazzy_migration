#!/usr/bin/env bash
# resources/dds-tuning.sh — CycloneDDS 버퍼/NIC 튜닝 (step 13, ★ 0Hz→29.98Hz).
#
# 왜: RealSense raw 큰 프레임(color 2.6MB / pointcloud 14.7MB)은 UDP 한 패킷에 안 들어가
#     IP fragment 로 쪼개진다. 받는 쪽 버퍼가 작으면 조각 유실 → 1프레임 복원 실패 → 0Hz.
# 핵심: 커널 천장(sysctl rmem_max)과 DDS 요청 버퍼(XML)를 "세트로" 올려야 한다.
#       천장만↑ → DDS 작게 요청해 무효 / XML만↑ → 천장에 깎여(clamp) 무효.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./config.sh
source "${SCRIPT_DIR}/config.sh"
config_assert_set

# 1) === 유선 NIC 자동 탐지 ===
#    wifi/docker/veth/가상/lo 제외, 물리 유선만. (DDS 가 유선 NIC 로만 통신하게 화이트리스트)
detect_wired_nic() {
    local nic
    for nic in /sys/class/net/*; do
        local name; name="$(basename "${nic}")"
        [[ "${name}" == "lo" ]] && continue
        [[ -d "${nic}/wireless" ]] && continue          # wifi 제외
        [[ "${name}" == docker* || "${name}" == veth* || "${name}" == br-* ]] && continue
        [[ ! -e "${nic}/device" ]] && continue           # 가상 NIC 제외 (물리만)
        echo "${name}"; return 0
    done
    return 1
}
NIC="${DDS_NETIF:-$(detect_wired_nic || true)}"
echo "dds-tuning: 유선 NIC = ${NIC:-(탐지 실패)}"

# 2) === 커널 sysctl (소켓 버퍼 천장) ===
#    노드 기동 "전에" 적용돼야 함 (도메인 생성 시 버퍼 요청을 천장이 받쳐줘야).
SYSCTL_FILE=/etc/sysctl.d/60-cyclonedds.conf
# TODO(A): 소켓 "수신" 버퍼 천장 키. (대용량 토픽 받는 쪽이라 receive 버퍼가 핵심)
#   [역할] net.core.??? — 소켓이 요청 가능한 receive 버퍼 최대치. (송신은 wmem_max)
sudo tee "${SYSCTL_FILE}" >/dev/null <<EOF
net.core.rmem_max=67108864
net.core.rmem_default=67108864
net.core.wmem_max=67108864
net.core.wmem_default=67108864
net.core.netdev_max_backlog=30000
EOF
sudo sysctl --system >/dev/null

# 3) === CycloneDDS XML 렌더 (DDS 실제 요청 버퍼 + NIC 화이트리스트) ===
#    원자적 쓰기: 임시파일에 먼저 쓰고 mv (부분 XML 이면 노드 즉사 → 방지).
mkdir -p "$(dirname "${CYCLONEDDS_XML}")"
tmp="$(mktemp)"
cat > "${tmp}" <<EOF
<CycloneDDS><Domain>
  <General>
    <Interfaces><NetworkInterface name="${NIC}"/></Interfaces>
  </General>
  <Internal>
    <SocketReceiveBufferSize min="64MB"/>
    <SocketSendBufferSize min="64MB"/>
  </Internal>
</Domain></CycloneDDS>
EOF
mv "${tmp}" "${CYCLONEDDS_XML}"
echo "dds-tuning: XML 렌더 → ${CYCLONEDDS_XML} (NIC=${NIC})"

# 4) === ~/.bashrc 에 RMW + URI 주입 (마커 블록, 멱등) ===
#    기존 블록 제거 후 재작성 → 중복 방지.
bashrc="${HOME}/.bashrc"
sed -i '/# >>> dds-tuning >>>/,/# <<< dds-tuning <<</d' "${bashrc}"
# TODO(B): .bashrc 에 export 할 두 변수. (host 노드가 cyclonedds 를 쓰게)
#   [역할] 하나는 "어떤 RMW 쓸지"(config 의 RMW_IMPLEMENTATION),
#          하나는 "XML 어디 있는지"(config 의 CYCLONEDDS_URI).
cat >> "${bashrc}" <<EOF
# >>> dds-tuning >>>
export RMW_IMPLEMENTATION=${RMW_IMPLEMENTATION}
export CYCLONEDDS_URI=${CYCLONEDDS_URI}
# <<< dds-tuning <<<
EOF

echo "dds-tuning: 완료 (새 터미널 또는 source ~/.bashrc 후 적용)"

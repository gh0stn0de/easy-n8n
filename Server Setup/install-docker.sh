#!/usr/bin/env bash
# =============================================================================
# Docker CE Installation Script for Ubuntu 26.04 LTS (Resolute Raccoon)
# Installs: Docker Engine 29.x, Docker CLI, containerd 2.x,
#           Docker Buildx plugin, Docker Compose v2 plugin
#
# Tested: Ubuntu 26.04 LTS, kernel 7.0.0, Docker CE 29.4.0, containerd 2.2.2
# Source: https://docs.docker.com/engine/install/ubuntu/
# Usage:  sudo bash install-docker-ubuntu2604.sh
# =============================================================================

set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── Root check ────────────────────────────────────────────────────────────────
[[ $EUID -ne 0 ]] && error "This script must be run as root. Use: sudo bash $0"

# ── OS check ─────────────────────────────────────────────────────────────────
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
else
    error "/etc/os-release not found. Cannot determine OS."
fi

if [[ "$ID" != "ubuntu" ]]; then
    error "This script is designed for Ubuntu. Detected: $ID"
fi

CODENAME="${VERSION_CODENAME:-}"
[[ -z "$CODENAME" ]] && error "Could not determine Ubuntu codename."

info "Detected: Ubuntu $VERSION ($CODENAME)"

# ── Step 1: Remove conflicting packages ──────────────────────────────────────
info "Removing any conflicting/old Docker packages..."
CONFLICTS=(
    docker.io docker-doc docker-compose docker-compose-v2
    podman-docker containerd runc
)
for pkg in "${CONFLICTS[@]}"; do
    if dpkg -l "$pkg" &>/dev/null; then
        warn "Removing conflicting package: $pkg"
        apt-get remove -y "$pkg"
    fi
done
success "Conflict removal complete."

# ── Step 2: Update apt and install prerequisites ──────────────────────────────
info "Updating package index and installing prerequisites..."
apt-get update -qq
apt-get install -y ca-certificates curl
success "Prerequisites installed."

# ── Step 3: Add Docker's official GPG key ─────────────────────────────────────
info "Adding Docker's GPG key..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
success "GPG key added."

# ── Step 4: Add Docker's apt repository ──────────────────────────────────────
info "Adding Docker apt repository (codename: $CODENAME)..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu \
$CODENAME stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null
success "Repository added: /etc/apt/sources.list.d/docker.list"

# ── Step 5: Install Docker Engine ─────────────────────────────────────────────
info "Updating package index and installing Docker CE..."
apt-get update -qq
apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
success "Docker CE installed."

# ── Step 6: Enable and start Docker ───────────────────────────────────────────
info "Enabling and starting Docker service..."
systemctl enable --now docker
success "Docker service is active."

# ── Step 7: Verify installation ───────────────────────────────────────────────
info "Verifying Docker versions..."
DOCKER_VER=$(docker --version 2>/dev/null || echo "unavailable")
COMPOSE_VER=$(docker compose version 2>/dev/null || echo "unavailable")
echo -e "  Docker Engine : ${GREEN}$DOCKER_VER${NC}"
echo -e "  Docker Compose: ${GREEN}$COMPOSE_VER${NC}"

# ── Step 8: Optional — add current user to docker group ───────────────────────
# Only runs when the script is invoked with sudo (i.e. SUDO_USER is set)
if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    info "Adding '$SUDO_USER' to the docker group (no more sudo for docker)..."
    usermod -aG docker "$SUDO_USER"
    warn "Log out and back in (or run: newgrp docker) for this to take effect."
fi

# ── Step 9: Optional daemon config — log rotation ─────────────────────────────
DAEMON_JSON="/etc/docker/daemon.json"
if [[ ! -f "$DAEMON_JSON" ]]; then
    info "Writing sensible default daemon config (log rotation + overlay2)..."
    cat > "$DAEMON_JSON" <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
    systemctl restart docker
    success "Daemon config applied and Docker restarted."
else
    warn "$DAEMON_JSON already exists — skipping default config write."
fi

# ── Step 10: Smoke test ────────────────────────────────────────────────────────
info "Running hello-world smoke test..."
if docker run --rm hello-world 2>&1 | grep -q "Hello from Docker"; then
    success "Smoke test passed — Docker is working correctly!"
else
    warn "Smoke test did not return expected output. Check: docker run --rm hello-world"
fi

# ── Done ───────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}  Docker CE installation complete on Ubuntu $VERSION${NC}"
echo -e "${GREEN}============================================================${NC}"
echo ""
echo "  Useful commands:"
echo "    docker ps                     # list running containers"
echo "    docker images                 # list local images"
echo "    docker compose up -d          # start a Compose stack"
echo "    docker system prune -a        # clean up unused resources"
echo "    sudo systemctl status docker  # check Docker daemon status"
echo ""
echo "  Docs: https://docs.docker.com/engine/install/ubuntu/"
echo ""
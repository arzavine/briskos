#!/bin/bash
# ==============================================================================
# BriskOS 1.0 LTS (Feather) - Containerized Docker Build Harness
# Builds the BriskOS ISO inside an isolated Debian Trixie container
# Compatible with Linux, macOS, Windows Docker Desktop, and WSL2
# ==============================================================================
set -euo pipefail

# Disable MSYS/MinGW POSIX-to-Windows path conversion when running under Git Bash on Windows
# Prevents docker -v "/d/...:/build" from being mangled into semicolon-separated paths
export MSYS_NO_PATHCONV=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

# Default parameters
IMAGE_TAG="briskos-builder:1.0"
FORCE_REBUILD=false
OPEN_SHELL=false
FORWARD_ARGS=()

# Colors & Formatting (ANSI)
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    COLOR_RESET='\033[0m'
    COLOR_BOLD='\033[1m'
    COLOR_RED='\033[0;31m'
    COLOR_GREEN='\033[0;32m'
    COLOR_YELLOW='\033[0;33m'
    COLOR_BLUE='\033[0;34m'
    COLOR_CYAN='\033[0;36m'
    COLOR_GRAY='\033[0;90m'
else
    COLOR_RESET=''
    COLOR_BOLD=''
    COLOR_RED=''
    COLOR_GREEN=''
    COLOR_YELLOW=''
    COLOR_BLUE=''
    COLOR_CYAN=''
    COLOR_GRAY=''
fi

log_info()    { echo -e "${COLOR_GRAY}[$(date '+%Y-%m-%d %H:%M:%S')]${COLOR_RESET} [${COLOR_CYAN}INFO${COLOR_RESET}] $*"; }
log_warn()    { echo -e "${COLOR_GRAY}[$(date '+%Y-%m-%d %H:%M:%S')]${COLOR_RESET} [${COLOR_YELLOW}WARN${COLOR_RESET}] $*"; }
log_error()   { echo -e "${COLOR_GRAY}[$(date '+%Y-%m-%d %H:%M:%S')]${COLOR_RESET} [${COLOR_RED}ERROR${COLOR_RESET}] $*"; }
log_success() { echo -e "${COLOR_GRAY}[$(date '+%Y-%m-%d %H:%M:%S')]${COLOR_RESET} [${COLOR_GREEN}SUCCESS${COLOR_RESET}] $*"; }

print_banner() {
    echo -e "${COLOR_CYAN}${COLOR_BOLD}"
    echo "======================================================================"
    echo "       BriskOS 1.0 (Feather) - Containerized Docker Builder           "
    echo "         Isolated Debian 13 (Trixie) Live-Build Environment           "
    echo "======================================================================"
    echo -e "${COLOR_RESET}"
    log_info "Project Root: ${PROJECT_ROOT}"
    log_info "Docker Image: ${IMAGE_TAG}"
}

show_usage() {
    cat << EOF
BriskOS Containerized Docker Build Harness

Usage: $0 [OPTIONS] [-- ADDITIONAL_BUILD_ISO_ARGS]

Options:
  -b, --build-image   Force rebuild of the Docker builder image
  -t, --tag TAG       Specify custom Docker image tag (Default: briskos-builder:1.0)
  -s, --shell         Open interactive bash shell inside build container for debugging
  -c, --clean         Forward clean request to container build script
      --no-clean      Forward no-clean request to container build script
  -d, --dry-run       Forward dry-run request to container build script
  -h, --help          Display this help message and exit

Examples:
  ./scripts/build-docker.sh               # Build image if needed and assemble ISO
  ./scripts/build-docker.sh --build-image # Force rebuild of Dockerfile before building
  ./scripts/build-docker.sh --dry-run     # Test live-build configuration inside container
  ./scripts/build-docker.sh --shell       # Drop into container root shell for diagnostics

Requirements:
  Docker Engine or Docker Desktop running with privileged container support.

EOF
}

check_docker() {
    log_info "Verifying Docker host environment..."

    if ! command -v docker &>/dev/null; then
        log_error "Docker is not installed or not available in PATH."
        echo ""
        echo "Installation instructions:"
        echo "  - Linux (Ubuntu/Debian): sudo apt update && sudo apt install -y docker.io"
        echo "  - Windows / macOS:       Install Docker Desktop (https://www.docker.com/products/docker-desktop)"
        echo "  - WSL2:                  Enable Docker Desktop WSL2 integration or install Docker Engine inside WSL2"
        echo ""
        exit 1
    fi

    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon is not running or current user does not have permission to access the socket."
        echo ""
        echo "Troubleshooting:"
        echo "  - Linux:   sudo systemctl start docker (or 'sudo usermod -aG docker \$USER' and re-login)"
        echo "  - Windows: Launch Docker Desktop and verify the whale icon shows 'Engine running'"
        echo ""
        exit 1
    fi

    log_success "Docker daemon verified and running."
}

build_image_if_needed() {
    local image_exists=false
    if docker image inspect "${IMAGE_TAG}" >/dev/null 2>&1; then
        image_exists=true
    fi

    if [ "${image_exists}" = false ] || [ "${FORCE_REBUILD}" = true ]; then
        if [ "${FORCE_REBUILD}" = true ]; then
            log_info "Force rebuilding Docker builder image (${IMAGE_TAG})..."
        else
            log_info "Docker builder image '${IMAGE_TAG}' not found locally. Building from Dockerfile..."
        fi

        docker build -t "${IMAGE_TAG}" -f "${PROJECT_ROOT}/Dockerfile" "${PROJECT_ROOT}"
        log_success "Docker builder image '${IMAGE_TAG}' ready."
    else
        log_success "Using existing Docker builder image '${IMAGE_TAG}'."
    fi
}

run_container() {
    local tty_flag=""
    if [ -t 0 ] && [ -t 1 ]; then
        tty_flag="-it"
    else
        tty_flag="-i"
    fi

    # Detect host user UID/GID so build container can adjust artifact ownership
    local host_uid
    local host_gid
    host_uid="$(id -u 2>/dev/null || echo 1000)"
    host_gid="$(id -g 2>/dev/null || echo 1000)"

    # Host-to-container mount paths
    local mount_src="${PROJECT_ROOT}"

    if [ "${OPEN_SHELL}" = true ]; then
        log_info "Launching interactive shell in container (${IMAGE_TAG})..."
        log_info "Inside container, workspace is mounted at /build"
        docker run --privileged --rm ${tty_flag} \
            -v "${mount_src}:/build" \
            -e "HOST_UID=${host_uid}" \
            -e "HOST_GID=${host_gid}" \
            --entrypoint /bin/bash \
            "${IMAGE_TAG}"
        return
    fi

    log_info "Executing BriskOS build inside container..."
    log_info "Forwarding arguments: ${FORWARD_ARGS[*]:-(default production build)}"
    
    if [ ${#FORWARD_ARGS[@]} -gt 0 ]; then
        docker run --privileged --rm ${tty_flag} \
            -v "${mount_src}:/build" \
            -e "HOST_UID=${host_uid}" \
            -e "HOST_GID=${host_gid}" \
            "${IMAGE_TAG}" "${FORWARD_ARGS[@]}"
    else
        docker run --privileged --rm ${tty_flag} \
            -v "${mount_src}:/build" \
            -e "HOST_UID=${host_uid}" \
            -e "HOST_GID=${host_gid}" \
            "${IMAGE_TAG}"
    fi

    log_success "Container build execution completed."
}

parse_arguments() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -b|--build-image)
                FORCE_REBUILD=true
                shift
                ;;
            -t|--tag)
                if [ -n "${2:-}" ]; then
                    IMAGE_TAG="$2"
                    shift 2
                else
                    log_error "Option --tag requires a tag argument."
                    exit 1
                fi
                ;;
            -s|--shell)
                OPEN_SHELL=true
                shift
                ;;
            -c|--clean)
                FORWARD_ARGS+=("--clean")
                shift
                ;;
            --no-clean)
                FORWARD_ARGS+=("--no-clean")
                shift
                ;;
            -d|--dry-run)
                FORWARD_ARGS+=("--dry-run")
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            --)
                shift
                FORWARD_ARGS+=("$@")
                break
                ;;
            *)
                # Forward any other flags (e.g. -o, -k, -v) to build-iso.sh
                FORWARD_ARGS+=("$1")
                shift
                ;;
        esac
    done
}

main() {
    parse_arguments "$@"
    print_banner
    check_docker
    build_image_if_needed
    run_container
}

main "$@"

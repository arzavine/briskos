#!/bin/bash
# ==============================================================================
# BriskOS ISO Build Script
# High-performance, lightweight Linux distribution build harness
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
LOG_DIR="${PROJECT_ROOT}/logs"
LOG_FILE="${LOG_DIR}/build_${TIMESTAMP}.log"

mkdir -p "${LOG_DIR}"

log() {
    local level="$1"
    shift
    local msg="$*"
    local formatted="[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] ${msg}"
    echo -e "${formatted}" | tee -a "${LOG_FILE}"
}

log_info()    { log "INFO" "$@"; }
log_warn()    { log "WARN" "$@"; }
log_error()   { log "ERROR" "$@"; }
log_success() { log "SUCCESS" "$@"; }

print_banner() {
    echo "======================================================================"
    echo "            BriskOS 1.0 (Feather) - ISO Build System                  "
    echo "======================================================================"
    log_info "Project root: ${PROJECT_ROOT}"
    log_info "Log destination: ${LOG_FILE}"
}

check_prerequisites() {
    log_info "Checking build environment and prerequisites..."

    # Check root privileges
    if [ "$(id -u)" -ne 0 ]; then
        log_error "Root privileges are required to run live-build (debootstrap, chroot, loop mounts)."
        log_error "Please run this script with sudo: sudo ./scripts/build-iso.sh"
        exit 1
    fi

    # Check required binaries
    local missing_tools=()
    local required_tools=("lb" "debootstrap" "xorriso" "mksquashfs")

    for tool in "${required_tools[@]}"; do
        if ! command -v "${tool}" &>/dev/null; then
            missing_tools+=("${tool}")
        fi
    done

    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "The following required build tools are missing: ${missing_tools[*]}"
        log_error "Please install them before proceeding. On Debian/Ubuntu:"
        log_error "  apt-get update && apt-get install -y live-build debootstrap xorriso squashfs-tools"
        exit 1
    fi

    log_success "All prerequisites satisfied."
}

clean_build() {
    log_info "Starting clean step (lb clean --purge)..."
    lb clean --purge 2>&1 | tee -a "${LOG_FILE}"
    log_success "Clean completed successfully."
}

configure_build() {
    log_info "Starting configuration step (lb config)..."
    if [ ! -f "auto/config" ]; then
        log_error "auto/config script not found in ${PROJECT_ROOT}/auto/config"
        exit 1
    fi

    chmod +x auto/config
    lb config 2>&1 | tee -a "${LOG_FILE}"
    log_success "Configuration completed successfully."
}

execute_build() {
    log_info "Starting live-build assembly step (lb build)..."
    log_info "This may take several minutes depending on network bandwidth and disk I/O."
    
    lb build 2>&1 | tee -a "${LOG_FILE}"
    log_success "Build step completed."
}

verify_artifact() {
    log_info "Verifying built ISO artifacts..."
    local iso_files
    iso_files=(BriskOS*.iso *.hybrid.iso *.iso)

    local found_iso=""
    for iso in "${iso_files[@]}"; do
        if [ -f "${iso}" ]; then
            found_iso="${iso}"
            break
        fi
    done

    if [ -n "${found_iso}" ] && [ -f "${found_iso}" ]; then
        local iso_size
        iso_size="$(du -h "${found_iso}" | cut -f1)"
        local iso_sha256
        iso_sha256="$(sha256sum "${found_iso}" | awk '{print $1}')"

        echo "======================================================================"
        log_success "BriskOS ISO created successfully!"
        log_info "Artifact: ${PROJECT_ROOT}/${found_iso}"
        log_info "Size: ${iso_size}"
        log_info "SHA256: ${iso_sha256}"
        echo "======================================================================"
    else
        log_error "No ISO image found in ${PROJECT_ROOT} after build completed."
        log_error "Please inspect the build log for details: ${LOG_FILE}"
        exit 1
    fi
}

main() {
    print_banner
    check_prerequisites
    clean_build
    configure_build
    execute_build
    verify_artifact
}

main "$@"

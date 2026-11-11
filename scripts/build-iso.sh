#!/bin/bash
# ==============================================================================
# BriskOS 1.0 LTS (Feather) - Production ISO Build Harness
# High-performance, lightweight Linux distribution build system
# Based on Debian 12 (Bookworm) amd64 | live-build framework
# ==============================================================================
set -euo pipefail

# ------------------------------------------------------------------------------
# Directory & Path Discovery
# ------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

# Default parameters
DO_CLEAN=true
DRY_RUN=false
VERBOSE=false
OUTPUT_DIR="${PROJECT_ROOT}"
KEEP_LOGS=10
MIN_FREE_DISK_GB=8

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

# Logging Setup
TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
LOG_DIR="${PROJECT_ROOT}/logs"
LOG_FILE="${LOG_DIR}/build_${TIMESTAMP}.log"
START_TIME="$(date +%s)"

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

# Helper to strip ANSI codes for log file
strip_ansi() {
    sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g'
}

log() {
    local level="$1"
    local color="$2"
    shift 2
    local msg="$*"
    local time_str
    time_str="$(date '+%Y-%m-%d %H:%M:%S')"
    
    # Console output with color
    echo -e "${COLOR_GRAY}[${time_str}]${COLOR_RESET} [${color}${level}${COLOR_RESET}] ${msg}"
    
    # Log file output without color
    echo "[${time_str}] [${level}] ${msg}" | strip_ansi >> "${LOG_FILE}"
}

log_info()    { log "INFO"    "${COLOR_CYAN}"   "$@"; }
log_warn()    { log "WARN"    "${COLOR_YELLOW}" "$@"; }
log_error()   { log "ERROR"   "${COLOR_RED}"    "$@"; }
log_success() { log "SUCCESS" "${COLOR_GREEN}"  "$@"; }

print_banner() {
    echo -e "${COLOR_CYAN}${COLOR_BOLD}"
    echo "======================================================================"
    echo "            BriskOS 1.0 (Feather) - ISO Build System                  "
    echo "          Debian 12 (Bookworm) amd64 | Stacking Wayland               "
    echo "======================================================================"
    echo -e "${COLOR_RESET}"
    log_info "Project root:    ${PROJECT_ROOT}"
    log_info "Log destination: ${LOG_FILE}"
    log_info "Output folder:   ${OUTPUT_DIR}"
    if [ "${DRY_RUN}" = true ]; then
        log_warn "MODE: DRY-RUN SIMULATION (Pre-flight checks and configuration audit)"
    fi
}

show_usage() {
    cat << EOF
BriskOS ISO Build System Harness

Usage: sudo $0 [OPTIONS]

Options:
  -c, --clean         Execute 'lb clean --purge' before building (Default: true)
      --no-clean      Skip clean step (useful for rapid incremental debugging)
  -d, --dry-run       Validate environment, tools, configs, and disk space without building
  -o, --output-dir    Specify custom directory for output ISO and checksums
  -k, --keep-logs N   Maximum number of timestamped build logs to retain (Default: 10)
  -v, --verbose       Enable verbose script debugging output
  -h, --help          Display this help message and exit

Examples:
  sudo $0                     # Standard pristine production build
  sudo $0 --dry-run           # Validate prerequisites and configuration
  sudo $0 --no-clean          # Rebuild without cleaning chroot cache
  sudo $0 -o /var/iso-output  # Build and place output in custom directory

EOF
}

# ------------------------------------------------------------------------------
# Log File Rotation
# ------------------------------------------------------------------------------
rotate_logs() {
    if [ ! -d "${LOG_DIR}" ]; then
        return
    fi
    
    local log_count
    log_count="$(find "${LOG_DIR}" -maxdepth 1 -name "build_*.log" -type f | wc -l)"
    
    if [ "${log_count}" -gt "${KEEP_LOGS}" ]; then
        log_info "Rotating build logs (keeping ${KEEP_LOGS} most recent)..."
        # Find logs sorted oldest first and remove excess
        find "${LOG_DIR}" -maxdepth 1 -name "build_*.log" -type f \
            | sort \
            | head -n -"${KEEP_LOGS}" \
            | while IFS= read -r old_log; do
                rm -f "${old_log}"
            done
    fi
}

# ------------------------------------------------------------------------------
# Prerequisite & Pre-Flight Checks
# ------------------------------------------------------------------------------
check_prerequisites() {
    log_info "Verifying build environment prerequisites..."

    # Check root privileges
    if [ "$(id -u)" -ne 0 ]; then
        if [ "${DRY_RUN}" = true ]; then
            log_warn "Dry-run mode: Running without root privileges. (Full build requires root/sudo)."
        else
            log_error "Root privileges are required to run live-build (debootstrap, chroot, loop mounts)."
            log_error "Please execute with sudo: sudo $0"
            exit 1
        fi
    else
        log_success "Root privileges verified."
    fi

    # Check required tools
    local missing_tools=()
    local required_tools=("lb" "debootstrap" "xorriso" "mksquashfs")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "${tool}" &>/dev/null; then
            missing_tools+=("${tool}")
        fi
    done

    # Additional utility tools check
    local recommended_tools=("dosfstools" "mtools" "grub-mkimage")
    for tool in "${recommended_tools[@]}"; do
        if ! command -v "${tool}" &>/dev/null; then
            log_warn "Recommended EFI/ISO tool not found in PATH: ${tool}"
        fi
    done

    if [ ${#missing_tools[@]} -gt 0 ]; then
        if [ "${DRY_RUN}" = true ]; then
            log_warn "Dry-run notice: The following build tools are missing from PATH: ${missing_tools[*]}"
            log_warn "Install before full build: sudo apt-get install -y live-build debootstrap xorriso squashfs-tools dosfstools mtools"
        else
            log_error "The following required build tools are missing from PATH:"
            for tool in "${missing_tools[@]}"; do
                echo -e "  - ${COLOR_RED}${tool}${COLOR_RESET}"
            done
            log_error "Please install required packages. On Debian/Ubuntu:"
            log_error "  sudo apt-get update && sudo apt-get install -y live-build debootstrap xorriso squashfs-tools dosfstools mtools grub-pc-bin grub-efi-amd64-bin binutils"
            exit 1
        fi
    else
        log_success "All required build binaries found: ${required_tools[*]}"
    fi

    # Check available disk space
    log_info "Checking available storage space on ${PROJECT_ROOT}..."
    local free_kb
    free_kb="$(df -Pk "${PROJECT_ROOT}" 2>/dev/null | awk 'NR==2 {print $4}' || echo "0")"
    if [ -n "${free_kb}" ] && [ "${free_kb}" -gt 0 ] 2>/dev/null; then
        local free_gb
        free_gb="$((free_kb / 1024 / 1024))"
        if [ "${free_gb}" -lt "${MIN_FREE_DISK_GB}" ]; then
            log_warn "Available disk space is ${free_gb} GB (Recommended: >= ${MIN_FREE_DISK_GB} GB for Bookworm live image assembly)."
            if [ "${DRY_RUN}" = false ]; then
                log_warn "Proceeding, but low disk space may cause mksquashfs or debootstrap to fail."
            fi
        else
            log_success "Sufficient storage space available: ${free_gb} GB free."
        fi
    else
        log_warn "Unable to determine free disk space automatically (continuing)."
    fi

    # Check configuration files
    log_info "Validating BriskOS configuration structure..."
    if [ ! -f "auto/config" ]; then
        log_error "Missing configuration script: auto/config"
        exit 1
    fi
    chmod +x auto/config
    log_success "Configuration script verified: auto/config"

    if [ ! -d "config/package-lists" ]; then
        log_error "Missing package lists directory: config/package-lists"
        exit 1
    fi

    local pkg_count
    pkg_count="$(find config/package-lists -name "*.list.chroot" | wc -l)"
    if [ "${pkg_count}" -eq 0 ]; then
        log_error "No .list.chroot files found in config/package-lists"
        exit 1
    fi
    log_success "Found ${pkg_count} live-build package list manifests."

    # Validate and ensure executable permissions on live hooks and chroot binaries
    if [ -d "config/hooks/live" ]; then
        find config/hooks/live -type f -name "*.hook.chroot" -exec chmod +x {} + 2>/dev/null || true
        local hook_count
        hook_count="$(find config/hooks/live -name "*.hook.chroot" | wc -l)"
        log_success "Chroot live hooks verified (${hook_count} hooks marked executable)."
    fi

    if [ -d "config/includes.chroot/usr/local/bin" ]; then
        find config/includes.chroot/usr/local/bin -type f -exec chmod +x {} + 2>/dev/null || true
        local bin_count
        bin_count="$(find config/includes.chroot/usr/local/bin -type f | wc -l)"
        log_success "Chroot /usr/local/bin custom scripts verified (${bin_count} binaries marked executable)."
    fi

    # Ensure output directory exists
    mkdir -p "${OUTPUT_DIR}"
    log_success "Pre-flight checks completed successfully."
}

# ------------------------------------------------------------------------------
# Build Pipeline Stages
# ------------------------------------------------------------------------------
clean_build() {
    if [ "${DO_CLEAN}" = false ]; then
        log_info "Clean step skipped (--no-clean flag specified)."
        return
    fi

    log_info "Starting clean step (lb clean --purge)..."
    if [ "${DRY_RUN}" = true ]; then
        log_info "[DRY-RUN] Simulated: lb clean --purge"
        return
    fi

    lb clean --purge 2>&1 | tee -a "${LOG_FILE}"
    log_success "Clean completed successfully."
}

configure_build() {
    log_info "Starting live-build configuration step (lb config)..."
    if [ "${DRY_RUN}" = true ]; then
        log_info "[DRY-RUN] Simulated: lb config (sourced from auto/config)"
        return
    fi

    lb config 2>&1 | tee -a "${LOG_FILE}"
    log_success "Configuration step completed successfully."
}

execute_build() {
    log_info "Starting live-build assembly step (lb build)..."
    log_info "Downloading Debian packages, creating rootfs, compressing squashfs, and building hybrid ISO..."
    
    if [ "${DRY_RUN}" = true ]; then
        log_info "[DRY-RUN] Simulated: lb build"
        log_success "[DRY-RUN] Build simulation completed successfully."
        return
    fi

    lb build 2>&1 | tee -a "${LOG_FILE}"
    log_success "Live-build process finished."
}

verify_artifact() {
    if [ "${DRY_RUN}" = true ]; then
        echo ""
        echo -e "${COLOR_GREEN}${COLOR_BOLD}======================================================================${COLOR_RESET}"
        echo -e "${COLOR_GREEN}${COLOR_BOLD}           BriskOS Dry-Run Verification Succeeded!                   ${COLOR_RESET}"
        echo -e "${COLOR_GREEN}${COLOR_BOLD}======================================================================${COLOR_RESET}"
        log_success "All configurations, manifests, hooks, and scripts passed pre-flight checks."
        log_info "To execute a real production build on Debian/Ubuntu or Docker:"
        log_info "  Native: sudo ./scripts/build-iso.sh"
        log_info "  Docker: ./scripts/build-docker.sh"
        echo -e "${COLOR_GREEN}${COLOR_BOLD}======================================================================${COLOR_RESET}"
        echo ""
        return
    fi

    log_info "Searching for generated ISO artifacts..."
    
    local candidate_isos=(
        "BriskOS-1.0-amd64.hybrid.iso"
        "BriskOS-1.0-amd64.iso"
        "live-image-amd64.hybrid.iso"
        "live-image-amd64.iso"
    )

    local found_iso=""
    for iso in "${candidate_isos[@]}"; do
        if [ -f "${iso}" ]; then
            found_iso="${iso}"
            break
        fi
    done

    # Fallback pattern search if candidates not matched exactly
    if [ -z "${found_iso}" ]; then
        for f in *.hybrid.iso *.iso; do
            if [ -f "${f}" ]; then
                found_iso="${f}"
                break
            fi
        done
    fi

    if [ -z "${found_iso}" ] || [ ! -f "${found_iso}" ]; then
        log_error "No ISO image found after build completion."
        log_error "Please review the build log for debootstrap or squashfs errors: ${LOG_FILE}"
        exit 1
    fi

    # Standardize final target filename as BriskOS-1.0-amd64.iso
    local canonical_iso="BriskOS-1.0-amd64.iso"
    if [ "${found_iso}" != "${canonical_iso}" ]; then
        log_info "Standardizing artifact '${found_iso}' -> '${canonical_iso}'..."
        cp -l "${found_iso}" "${canonical_iso}" 2>/dev/null || cp "${found_iso}" "${canonical_iso}"
    fi

    # Move/Copy to custom output directory if different from project root
    local final_iso_path="${canonical_iso}"
    if [ "${OUTPUT_DIR}" != "${PROJECT_ROOT}" ]; then
        cp "${canonical_iso}" "${OUTPUT_DIR}/${canonical_iso}"
        final_iso_path="${OUTPUT_DIR}/${canonical_iso}"
    fi

    log_info "Generating cryptographic checksums (SHA256 & SHA512)..."
    local sha256_val
    sha256_val="$(sha256sum "${final_iso_path}" | awk '{print $1}')"
    echo "${sha256_val}  $(basename "${final_iso_path}")" > "${final_iso_path}.sha256"

    local sha512_val
    sha512_val="$(sha512sum "${final_iso_path}" | awk '{print $1}')"
    echo "${sha512_val}  $(basename "${final_iso_path}")" > "${final_iso_path}.sha512"

    local iso_size
    iso_size="$(du -h "${final_iso_path}" | cut -f1)"
    
    local end_time
    end_time="$(date +%s)"
    local duration="$((end_time - START_TIME))"
    local minutes="$((duration / 60))"
    local seconds="$((duration % 60))"

    echo ""
    echo -e "${COLOR_GREEN}${COLOR_BOLD}======================================================================${COLOR_RESET}"
    echo -e "${COLOR_GREEN}${COLOR_BOLD}           BriskOS 1.0 (Feather) ISO Built Successfully!             ${COLOR_RESET}"
    echo -e "${COLOR_GREEN}${COLOR_BOLD}======================================================================${COLOR_RESET}"
    log_success "Artifact Path: ${final_iso_path}"
    log_success "File Size:     ${iso_size}"
    log_success "SHA256:        ${sha256_val}"
    log_success "SHA256 File:   ${final_iso_path}.sha256"
    log_success "SHA512 File:   ${final_iso_path}.sha512"
    log_success "Elapsed Time:  ${minutes}m ${seconds}s"
    log_success "Build Log:     ${LOG_FILE}"
    echo -e "${COLOR_GREEN}${COLOR_BOLD}======================================================================${COLOR_RESET}"
    echo ""
}

# ------------------------------------------------------------------------------
# Error Handler
# ------------------------------------------------------------------------------
handle_error() {
    local exit_code="$?"
    local line_no="$1"
    echo ""
    log_error "Build pipeline failed at line ${line_no} with exit status ${exit_code}."
    log_error "Review detailed log output: ${LOG_FILE}"
    if [ -f "${LOG_FILE}" ]; then
        echo -e "${COLOR_YELLOW}--- Last 20 lines of build log ---${COLOR_RESET}"
        tail -n 20 "${LOG_FILE}" | strip_ansi || true
        echo -e "${COLOR_YELLOW}----------------------------------${COLOR_RESET}"
    fi
    exit "${exit_code}"
}

trap 'handle_error $LINENO' ERR

# ------------------------------------------------------------------------------
# Argument Parsing & Main Execution
# ------------------------------------------------------------------------------
parse_arguments() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -c|--clean)
                DO_CLEAN=true
                shift
                ;;
            --no-clean)
                DO_CLEAN=false
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -o|--output-dir)
                if [ -n "${2:-}" ]; then
                    OUTPUT_DIR="$2"
                    shift 2
                else
                    log_error "Option --output-dir requires a valid directory argument."
                    exit 1
                fi
                ;;
            -k|--keep-logs)
                if [ -n "${2:-}" ] && [ "$2" -eq "$2" ] 2>/dev/null; then
                    KEEP_LOGS="$2"
                    shift 2
                else
                    log_error "Option --keep-logs requires an integer argument."
                    exit 1
                fi
                ;;
            -v|--verbose)
                VERBOSE=true
                set -x
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

main() {
    parse_arguments "$@"
    rotate_logs
    print_banner
    check_prerequisites
    clean_build
    configure_build
    execute_build
    verify_artifact
}

main "$@"

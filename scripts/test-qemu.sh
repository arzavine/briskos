#!/bin/bash
# ==============================================================================
# BriskOS 1.0 LTS (Feather) - QEMU Virtual Machine Test Harness
# High-performance, lightweight testing environment for Linux, WSL2, and macOS
# Debian 13 (Trixie) amd64 | Wayland Labwc Desktop | PipeWire Audio
# ==============================================================================
set -euo pipefail

# ------------------------------------------------------------------------------
# Directory & Path Discovery
# ------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

# Default parameters
ISO_PATH=""
RAM="2048M"
SMP="2"
BOOT_MODE="legacy"          # "legacy" or "uefi"
CUSTOM_OVMF=""
CREATE_DISK=false
DISK_PATH="${PROJECT_ROOT}/briskos-test.qcow2"
DISK_SIZE="20G"
ENABLE_KVM="auto"           # "auto", "true", or "false"
DISPLAY_BACKEND="default"
VGA_DEVICE="virtio"
AUDIO_BACKEND="auto"
DRY_RUN=false
VERBOSE=false
EXTRA_QEMU_ARGS=()

# ------------------------------------------------------------------------------
# Colors & Formatting (ANSI)
# ------------------------------------------------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    COLOR_RESET='\033[0m'
    COLOR_BOLD='\033[1m'
    COLOR_DIM='\033[2m'
    COLOR_RED='\033[0;31m'
    COLOR_GREEN='\033[0;32m'
    COLOR_YELLOW='\033[0;33m'
    COLOR_BLUE='\033[0;34m'
    COLOR_MAGENTA='\033[0;35m'
    COLOR_CYAN='\033[0;36m'
    COLOR_WHITE='\033[1;37m'
    COLOR_GRAY='\033[0;90m'
else
    COLOR_RESET=''
    COLOR_BOLD=''
    COLOR_DIM=''
    COLOR_RED=''
    COLOR_GREEN=''
    COLOR_YELLOW=''
    COLOR_BLUE=''
    COLOR_MAGENTA=''
    COLOR_CYAN=''
    COLOR_WHITE=''
    COLOR_GRAY=''
fi

# ------------------------------------------------------------------------------
# Diagnostic Logging Helpers
# ------------------------------------------------------------------------------
log_info()    { echo -e "${COLOR_CYAN}[INFO]${COLOR_RESET}    $*"; }
log_warn()    { echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET}    $*"; }
log_error()   { echo -e "${COLOR_RED}[ERROR]${COLOR_RESET}   $*" >&2; }
log_success() { echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $*"; }
log_kv()      { printf "${COLOR_GRAY}  %-20s${COLOR_RESET} : ${COLOR_WHITE}%s${COLOR_RESET}\n" "$1" "$2"; }

print_banner() {
    echo -e "${COLOR_CYAN}${COLOR_BOLD}"
    echo "======================================================================"
    echo "         BriskOS 1.0 (Feather) - QEMU Virtual Machine Test Harness    "
    echo "       Debian 13 Trixie amd64 | Stacking Wayland (Labwc Desktop)      "
    echo "======================================================================"
    echo -e "${COLOR_RESET}"
}

show_usage() {
    cat << EOF
BriskOS QEMU Virtual Machine Test Harness

Usage: $0 [OPTIONS] [-- ADDITIONAL_QEMU_FLAGS...]

Options:
  -i, --iso <path>         Path to BriskOS ISO image (default: auto-detected)
  -m, --ram <size>         Memory allocation (default: 2048M, e.g. 2048M, 4G)
  -c, -s, --smp <cores>    Virtual CPU cores (default: 2)
  -u, --uefi [path]        Boot in UEFI mode via OVMF firmware (auto-detected if path omitted)
  -b, --bios               Boot in Legacy BIOS mode (default)
  -d, --create-disk [size] Create and attach a sparse test disk (default: 20G, format: qcow2)
      --disk-file <path>   Custom path for test disk (default: briskos-test.qcow2)
  -k, --enable-kvm         Force enable KVM hardware virtualization
      --no-kvm, --tcg      Disable acceleration and force TCG software emulation
      --vga <device>       Video adapter: virtio, virtio-vga, virtio-gpu-pci, std (default: virtio)
      --display <backend>  Display backend: default, gtk, sdl, cocoa (default: default)
      --audio <driver>     Host audio driver: auto, pa, alsa, coreaudio, sdl, none (default: auto)
      --dry-run            Print the resolved QEMU command line and configuration without executing
  -v, --verbose            Enable verbose diagnostic output
  -h, --help               Display this help message and exit

Examples:
  $0                                      # Auto-detects ISO and launches with KVM, 2GB RAM, 2 CPUs
  $0 --uefi                               # Test booting under UEFI / OVMF firmware
  $0 --create-disk                        # Attach a 20GB qcow2 test disk for partition/installer testing
  $0 -i BriskOS-1.0-amd64.iso -m 4G -s 4   # Launch with 4GB RAM and 4 CPU cores
  $0 --dry-run                            # Audit QEMU flags and host capabilities without launching

EOF
}

# ------------------------------------------------------------------------------
# Argument Parsing
# ------------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--iso)
            if [[ $# -lt 2 || "$2" == -* ]]; then
                log_error "Option '$1' requires an ISO file path."
                exit 1
            fi
            ISO_PATH="$2"
            shift 2
            ;;
        -m|--ram)
            if [[ $# -lt 2 || "$2" == -* ]]; then
                log_error "Option '$1' requires a memory specification (e.g., 2048M, 4G)."
                exit 1
            fi
            RAM="$2"
            shift 2
            ;;
        -c|-s|--smp)
            if [[ $# -lt 2 || "$2" == -* ]]; then
                log_error "Option '$1' requires a CPU core count (e.g., 2, 4)."
                exit 1
            fi
            SMP="$2"
            shift 2
            ;;
        -u|--uefi)
            BOOT_MODE="uefi"
            if [[ $# -ge 2 && "$2" != -* ]]; then
                CUSTOM_OVMF="$2"
                shift 2
            else
                shift 1
            fi
            ;;
        -b|--bios)
            BOOT_MODE="legacy"
            shift 1
            ;;
        -d|--create-disk)
            CREATE_DISK=true
            if [[ $# -ge 2 && "$2" != -* ]]; then
                DISK_SIZE="$2"
                shift 2
            else
                shift 1
            fi
            ;;
        --disk-file)
            if [[ $# -lt 2 || "$2" == -* ]]; then
                log_error "Option '$1' requires a disk image file path."
                exit 1
            fi
            DISK_PATH="$2"
            shift 2
            ;;
        -k|--enable-kvm)
            ENABLE_KVM="true"
            shift 1
            ;;
        --no-kvm|--tcg|--no-accel)
            ENABLE_KVM="false"
            shift 1
            ;;
        --vga)
            if [[ $# -lt 2 || "$2" == -* ]]; then
                log_error "Option '$1' requires a VGA device type (e.g., virtio, std)."
                exit 1
            fi
            VGA_DEVICE="$2"
            shift 2
            ;;
        --display)
            if [[ $# -lt 2 || "$2" == -* ]]; then
                log_error "Option '$1' requires a display backend (e.g., default, gtk, sdl, cocoa)."
                exit 1
            fi
            DISPLAY_BACKEND="$2"
            shift 2
            ;;
        --audio)
            if [[ $# -lt 2 || "$2" == -* ]]; then
                log_error "Option '$1' requires an audio driver (e.g., auto, pa, alsa, coreaudio, none)."
                exit 1
            fi
            AUDIO_BACKEND="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift 1
            ;;
        -v|--verbose)
            VERBOSE=true
            shift 1
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        --)
            shift
            EXTRA_QEMU_ARGS=("$@")
            break
            ;;
        *)
            log_error "Unrecognized parameter: $1"
            echo "Run '$0 --help' for available options."
            exit 1
            ;;
    esac
done

print_banner

# ------------------------------------------------------------------------------
# Pre-Flight Check 1: QEMU Binary Availability
# ------------------------------------------------------------------------------
QEMU_BIN=""
if command -v qemu-system-x86_64 >/dev/null 2>&1; then
    QEMU_BIN="$(command -v qemu-system-x86_64)"
elif [ -x "/usr/bin/qemu-system-x86_64" ]; then
    QEMU_BIN="/usr/bin/qemu-system-x86_64"
elif [ -x "/usr/local/bin/qemu-system-x86_64" ]; then
    QEMU_BIN="/usr/local/bin/qemu-system-x86_64"
elif [ -x "/opt/homebrew/bin/qemu-system-x86_64" ]; then
    QEMU_BIN="/opt/homebrew/bin/qemu-system-x86_64"
else
    log_error "QEMU emulator binary 'qemu-system-x86_64' was not found in PATH."
    echo ""
    echo "To install QEMU on your system:"
    echo "  - Debian / Ubuntu / Mint : sudo apt-get update && sudo apt-get install -y qemu-system-x86 ovmf qemu-utils"
    echo "  - Fedora / RHEL / Alma   : sudo dnf install -y qemu-system-x86 edk2-ovmf qemu-img"
    echo "  - Arch Linux / Manjaro   : sudo pacman -S qemu-system-x86 edk2-ovmf"
    echo "  - macOS (Homebrew)       : brew install qemu"
    echo "  - Windows WSL2           : sudo apt-get update && sudo apt-get install -y qemu-system-x86 ovmf"
    echo ""
    exit 1
fi

QEMU_VERSION="$("${QEMU_BIN}" --version | head -n 1)"

# ------------------------------------------------------------------------------
# Pre-Flight Check 2: ISO Discovery
# ------------------------------------------------------------------------------
if [ -n "${ISO_PATH}" ]; then
    if [ ! -f "${ISO_PATH}" ]; then
        log_error "Specified ISO file does not exist: ${ISO_PATH}"
        exit 1
    fi
else
    # Auto-detection sequence
    CANDIDATES=(
        "${PROJECT_ROOT}/BriskOS-1.0-amd64.iso"
        "${PWD}/BriskOS-1.0-amd64.iso"
    )

    # Add any matching glob patterns
    shopt -s nullglob
    GLOB_MATCHES=("${PROJECT_ROOT}"/BriskOS-*.iso "${PROJECT_ROOT}"/live-image-*.iso "${PWD}"/*.iso)
    shopt -u nullglob

    CANDIDATES+=("${GLOB_MATCHES[@]}")

    for candidate in "${CANDIDATES[@]}"; do
        if [ -f "${candidate}" ]; then
            ISO_PATH="${candidate}"
            break
        fi
    done

    if [ -z "${ISO_PATH}" ]; then
        log_error "No BriskOS ISO image found in current directory or project root."
        echo ""
        echo "Expected artifact: BriskOS-1.0-amd64.iso"
        echo "You can either:"
        echo "  1. Build the ISO first: sudo ./scripts/build-iso.sh"
        echo "  2. Specify an existing ISO explicitly: $0 --iso /path/to/image.iso"
        echo ""
        exit 1
    fi
fi

ISO_SIZE="$(du -h "${ISO_PATH}" | cut -f1)"

# ------------------------------------------------------------------------------
# Host Environment & Virtualization Acceleration Detection
# ------------------------------------------------------------------------------
HOST_OS="$(uname -s)"
HOST_ARCH="$(uname -m)"
ACCEL_FLAG=()
CPU_MODEL="max"
ACCEL_DESC=""

case "${HOST_OS}" in
    Linux*)
        if [ "${ENABLE_KVM}" = "false" ]; then
            ACCEL_FLAG=("-accel" "tcg")
            CPU_MODEL="max"
            ACCEL_DESC="TCG (Software Emulation, forced via --no-kvm)"
        elif [ -e "/dev/kvm" ]; then
            if [ -r "/dev/kvm" ] && [ -w "/dev/kvm" ]; then
                ACCEL_FLAG=("-enable-kvm")
                CPU_MODEL="host"
                ACCEL_DESC="KVM (Hardware Accelerated via /dev/kvm)"
            else
                log_warn "/dev/kvm detected but current user lacks read/write permissions."
                log_warn "Add user to kvm group: 'sudo usermod -aG kvm \$USER' or run with sudo."
                if [ "${ENABLE_KVM}" = "true" ]; then
                    log_error "KVM hardware acceleration was explicitly requested but /dev/kvm is not accessible."
                    exit 1
                else
                    log_warn "Falling back to TCG software emulation."
                    ACCEL_FLAG=("-accel" "tcg")
                    CPU_MODEL="max"
                    ACCEL_DESC="TCG (Software Emulation, permission denied on /dev/kvm)"
                fi
            fi
        else
            if [ "${ENABLE_KVM}" = "true" ]; then
                log_error "KVM requested but /dev/kvm does not exist on this host."
                exit 1
            else
                ACCEL_FLAG=("-accel" "tcg")
                CPU_MODEL="max"
                ACCEL_DESC="TCG (Software Emulation, /dev/kvm not found)"
            fi
        fi
        ;;
    Darwin*)
        if [ "${ENABLE_KVM}" = "false" ]; then
            ACCEL_FLAG=("-accel" "tcg")
            CPU_MODEL="max"
            ACCEL_DESC="TCG (Software Emulation, forced)"
        elif "${QEMU_BIN}" -accel help 2>&1 | grep -q "hvf"; then
            ACCEL_FLAG=("-accel" "hvf")
            CPU_MODEL="host"
            ACCEL_DESC="Apple Hypervisor.framework (HVF Hardware Accelerated)"
        else
            ACCEL_FLAG=("-accel" "tcg")
            CPU_MODEL="max"
            ACCEL_DESC="TCG (Software Emulation, HVF unavailable)"
        fi
        ;;
    CYGWIN*|MINGW*|MSYS*)
        if "${QEMU_BIN}" -accel help 2>&1 | grep -q "whpx"; then
            ACCEL_FLAG=("-accel" "whpx" "-accel" "tcg")
            CPU_MODEL="host"
            ACCEL_DESC="Windows Hypervisor Platform (WHPX) with TCG fallback"
        else
            ACCEL_FLAG=("-accel" "tcg")
            CPU_MODEL="max"
            ACCEL_DESC="TCG (Software Emulation)"
        fi
        ;;
    *)
        ACCEL_FLAG=("-accel" "tcg")
        CPU_MODEL="max"
        ACCEL_DESC="TCG (Software Emulation, generic host: ${HOST_OS})"
        ;;
esac

# ------------------------------------------------------------------------------
# Firmware Detection (UEFI OVMF vs Legacy BIOS)
# ------------------------------------------------------------------------------
FIRMWARE_FLAG=()
FIRMWARE_DESC="Legacy BIOS (x86_64 SeaBIOS standard)"

if [ "${BOOT_MODE}" = "uefi" ]; then
    OVMF_CODE=""
    if [ -n "${CUSTOM_OVMF}" ]; then
        if [ -f "${CUSTOM_OVMF}" ]; then
            OVMF_CODE="${CUSTOM_OVMF}"
        else
            log_error "Specified OVMF firmware file not found: ${CUSTOM_OVMF}"
            exit 1
        fi
    else
        # Auto-detect standard OVMF locations across Linux distros & Homebrew
        SEARCH_PATHS=(
            "/usr/share/OVMF/OVMF_CODE.fd"
            "/usr/share/OVMF/OVMF_CODE_4M.fd"
            "/usr/share/OVMF/OVMF.fd"
            "/usr/share/ovmf/OVMF.fd"
            "/usr/share/edk2-ovmf/x64/OVMF_CODE.fd"
            "/usr/share/edk2-ovmf/OVMF_CODE.fd"
            "/usr/share/edk2/ovmf/OVMF_CODE.fd"
            "/usr/share/qemu/OVMF.fd"
            "/opt/homebrew/share/qemu/edk2-x86_64-code.fd"
            "/usr/local/share/qemu/edk2-x86_64-code.fd"
        )
        for path in "${SEARCH_PATHS[@]}"; do
            if [ -f "${path}" ]; then
                OVMF_CODE="${path}"
                break
            fi
        done
    fi

    if [ -n "${OVMF_CODE}" ]; then
        OVMF_VARS_SRC=""
        VARS_CANDIDATES=(
            "${OVMF_CODE/OVMF_CODE_4M.fd/OVMF_VARS_4M.fd}"
            "${OVMF_CODE/OVMF_CODE.fd/OVMF_VARS.fd}"
            "${OVMF_CODE/edk2-x86_64-code.fd/edk2-i386-vars.fd}"
            "/usr/share/OVMF/OVMF_VARS_4M.fd"
            "/usr/share/OVMF/OVMF_VARS.fd"
            "/usr/share/edk2-ovmf/x64/OVMF_VARS.fd"
            "/usr/share/edk2-ovmf/OVMF_VARS.fd"
            "/usr/share/edk2/ovmf/OVMF_VARS.fd"
        )
        # Only pair VARS with split CODE images (skip unified OVMF.fd images)
        if [[ "${OVMF_CODE}" == *CODE* || "${OVMF_CODE}" == *code* ]]; then
            for vpath in "${VARS_CANDIDATES[@]}"; do
                if [ -f "${vpath}" ]; then
                    OVMF_VARS_SRC="${vpath}"
                    break
                fi
            done
        fi

        if [ -n "${OVMF_VARS_SRC}" ]; then
            if [ "${CREATE_DISK}" = true ]; then
                OVMF_VARS_RW="${DISK_PATH%.qcow2}-ovmf-vars.fd"
            else
                OVMF_VARS_RW="${TMPDIR:-/tmp}/briskos-ovmf-vars.fd"
            fi
            if [ "${DRY_RUN}" = false ] && [ ! -f "${OVMF_VARS_RW}" ]; then
                cp "${OVMF_VARS_SRC}" "${OVMF_VARS_RW}"
            fi
            FIRMWARE_FLAG=(
                "-drive" "if=pflash,format=raw,readonly=on,file=${OVMF_CODE}"
                "-drive" "if=pflash,format=raw,file=${OVMF_VARS_RW}"
            )
            FIRMWARE_DESC="UEFI x86_64 pflash (${OVMF_CODE} + writable VARS)"
        else
            FIRMWARE_FLAG=("-bios" "${OVMF_CODE}")
            FIRMWARE_DESC="UEFI x86_64 (${OVMF_CODE})"
        fi
    else
        log_warn "UEFI mode requested, but no OVMF/EDK2 firmware image was found."
        log_warn "Install OVMF package (e.g., 'sudo apt-get install ovmf' or 'brew install qemu')."
        log_warn "Falling back gracefully to Legacy BIOS mode."
        FIRMWARE_DESC="Legacy BIOS (Fallback: OVMF not located)"
    fi
fi

# ------------------------------------------------------------------------------
# Storage Setup: Sparse Virtual Hard Disk (Optional)
# ------------------------------------------------------------------------------
DISK_FLAG=()
DISK_DESC="None (Live ISO only, non-destructive test)"

if [ "${CREATE_DISK}" = true ]; then
    if [ ! -f "${DISK_PATH}" ]; then
        log_info "Creating sparse qcow2 test disk: ${DISK_PATH} (${DISK_SIZE})..."
        if command -v qemu-img >/dev/null 2>&1; then
            qemu-img create -f qcow2 "${DISK_PATH}" "${DISK_SIZE}" >/dev/null
            log_success "Sparse virtual disk initialized successfully."
        else
            log_warn "'qemu-img' not found; attempting QEMU disk auto-provisioning."
        fi
    else
        log_info "Reusing existing virtual test disk: ${DISK_PATH}"
    fi
    DISK_FLAG=("-drive" "file=${DISK_PATH},if=virtio,format=qcow2,cache=writeback")
    DISK_DESC="${DISK_PATH} (${DISK_SIZE} VirtIO qcow2)"
fi

# ------------------------------------------------------------------------------
# Video & Display Setup
# ------------------------------------------------------------------------------
# VirtIO VGA provides hardware cursor, resolution switching, and Wayland performance
VGA_FLAG=("-vga" "${VGA_DEVICE}")

# Display backend selection
DISPLAY_FLAG=()
if [ -n "${DISPLAY_BACKEND}" ] && [ "${DISPLAY_BACKEND}" != "default" ]; then
    DISPLAY_FLAG=("-display" "${DISPLAY_BACKEND}")
fi

# ------------------------------------------------------------------------------
# Audio Setup (Intel HDA Emulation for PipeWire Sound Testing)
# ------------------------------------------------------------------------------
AUDIO_FLAG=()
AUDIO_DESC=""

if [ "${AUDIO_BACKEND}" = "auto" ]; then
    case "${HOST_OS}" in
        Darwin*)
            AUDIO_BACKEND="coreaudio"
            ;;
        Linux*)
            # Check for running PipeWire or PulseAudio daemon
            if [ -n "${PULSE_SERVER:-}" ] || pgrep -x "pipewire" >/dev/null 2>&1 || pgrep -x "pulseaudio" >/dev/null 2>&1; then
                AUDIO_BACKEND="pa"
            elif [ -e "/dev/snd" ]; then
                AUDIO_BACKEND="alsa"
            else
                AUDIO_BACKEND="none"
            fi
            ;;
        *)
            AUDIO_BACKEND="none"
            ;;
    esac
fi

# Probe QEMU supported audiodev backends
if "${QEMU_BIN}" -audiodev help 2>&1 | grep -qE "(pa|pulse|alsa|coreaudio|sdl|none)"; then
    AUDIO_FLAG=(
        "-audiodev" "${AUDIO_BACKEND},id=snd0"
        "-device" "intel-hda"
        "-device" "hda-duplex,audiodev=snd0"
    )
    AUDIO_DESC="Intel HDA duplex -> Host [${AUDIO_BACKEND}]"
else
    # Graceful fallback for older QEMU builds
    AUDIO_FLAG=("-device" "intel-hda" "-device" "hda-duplex")
    AUDIO_DESC="Intel HDA duplex (Legacy backend)"
fi

# ------------------------------------------------------------------------------
# Input & Network Devices
# ------------------------------------------------------------------------------
# VirtIO Tablet ensures absolute pointer coordinates without grabbing mouse in Wayland
INPUT_FLAG=("-device" "virtio-tablet-pci")

# VirtIO Network with user-mode stack and optional SSH port forwarding
NET_FLAG=(
    "-netdev" "user,id=net0,hostfwd=tcp::2222-:22"
    "-device" "virtio-net-pci,netdev=net0"
)

# ------------------------------------------------------------------------------
# Diagnostic Configuration Summary
# ------------------------------------------------------------------------------
echo -e "${COLOR_WHITE}${COLOR_BOLD}Virtual Machine Configuration:${COLOR_RESET}"
log_kv "QEMU Binary"     "${QEMU_BIN} (${QEMU_VERSION})"
log_kv "Host Platform"   "${HOST_OS} ${HOST_ARCH}"
log_kv "Target ISO"      "${ISO_PATH} (${ISO_SIZE})"
log_kv "Memory (RAM)"    "${RAM}"
log_kv "Virtual Cores"   "${SMP} vCPUs (Model: ${CPU_MODEL})"
log_kv "Virtualization"  "${ACCEL_DESC}"
log_kv "Firmware Mode"   "${FIRMWARE_DESC}"
log_kv "Graphics Adapter" "VirtIO VGA (${VGA_DEVICE})"
log_kv "Audio Subsystem" "${AUDIO_DESC}"
log_kv "Test Storage"    "${DISK_DESC}"
log_kv "Network Adapter" "VirtIO Net (User NAT, SSH forwarded to localhost:2222)"
echo "----------------------------------------------------------------------"

# ------------------------------------------------------------------------------
# Build Final QEMU Command Array
# ------------------------------------------------------------------------------
QEMU_CMD=(
    "${QEMU_BIN}"
    "${ACCEL_FLAG[@]}"
    "-cpu" "${CPU_MODEL}"
    "-m" "${RAM}"
    "-smp" "${SMP}"
    "${FIRMWARE_FLAG[@]}"
    "${VGA_FLAG[@]}"
    "${DISPLAY_FLAG[@]}"
    "${INPUT_FLAG[@]}"
    "${AUDIO_FLAG[@]}"
    "${NET_FLAG[@]}"
    "-boot" "d"
    "-cdrom" "${ISO_PATH}"
)

if [ "${CREATE_DISK}" = true ]; then
    QEMU_CMD+=("${DISK_FLAG[@]}")
fi

if [ ${#EXTRA_QEMU_ARGS[@]} -gt 0 ]; then
    QEMU_CMD+=("${EXTRA_QEMU_ARGS[@]}")
fi

if [ "${DRY_RUN}" = true ]; then
    echo ""
    log_warn "DRY-RUN SIMULATION ACTIVE: The following command would be executed:"
    echo ""
    echo -e "${COLOR_GREEN}${QEMU_CMD[*]}${COLOR_RESET}"
    echo ""
    log_success "Pre-flight audit passed successfully. Exiting without VM spawn."
    exit 0
fi

# ------------------------------------------------------------------------------
# Launch Virtual Machine
# ------------------------------------------------------------------------------
log_info "Spawning BriskOS virtual machine..."
echo -e "${COLOR_GRAY}Press Ctrl+Alt+G or Ctrl+Alt to release mouse capture if needed.${COLOR_RESET}"
echo ""

exec "${QEMU_CMD[@]}"

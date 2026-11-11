#!/bin/bash
# ==============================================================================
# BriskOS 1.0 LTS (Feather) - USB Flash Utility
# Safe, interactive bootable USB installer creation utility
# Based on Debian 12 (Bookworm) amd64 live-build hybrid ISO specification
# ==============================================================================
set -euo pipefail

# ------------------------------------------------------------------------------
# Directory Discovery & Constants
# ------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ANSI Color Codes (disabled if not terminal or NO_COLOR is set)
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

# ------------------------------------------------------------------------------
# Logging Functions
# ------------------------------------------------------------------------------
log_info()    { echo -e "${COLOR_GRAY}[INFO]${COLOR_RESET}    ${COLOR_CYAN}$*${COLOR_RESET}"; }
log_warn()    { echo -e "${COLOR_YELLOW}${COLOR_BOLD}[WARN]${COLOR_RESET}    ${COLOR_YELLOW}$*${COLOR_RESET}"; }
log_error()   { echo -e "${COLOR_RED}${COLOR_BOLD}[ERROR]${COLOR_RESET}   ${COLOR_RED}$*${COLOR_RESET}" >&2; }
log_success() { echo -e "${COLOR_GREEN}${COLOR_BOLD}[SUCCESS]${COLOR_RESET} ${COLOR_GREEN}$*${COLOR_RESET}"; }

print_banner() {
    echo -e "${COLOR_CYAN}${COLOR_BOLD}"
    echo "======================================================================"
    echo "         BriskOS 1.0 (Feather) - Bootable USB Flash Utility           "
    echo "            Safe Raw Disk Image Writer (Strict Safety Check)          "
    echo "======================================================================"
    echo -e "${COLOR_RESET}"
}

show_usage() {
    local script_name
    script_name="$(basename "$0")"
    cat << EOF
BriskOS Bootable USB Flash Utility

Usage: sudo ./${script_name} [OPTIONS] [ISO_PATH]

Arguments:
  ISO_PATH                   Path to the BriskOS ISO image (optional, prompts if omitted)

Options:
  -i, --iso <path>           Specify path to BriskOS ISO image
  -d, --device <dev>         Target block device (e.g. sdb or /dev/sdb)
  -l, --list                 List detected removable USB drives and exit
  -h, --help                 Display this help screen and exit

Examples:
  sudo ./${script_name}
  sudo ./${script_name} BriskOS-1.0-amd64.iso
  sudo ./${script_name} --iso /path/to/BriskOS-1.0-amd64.iso --device sdb
  sudo ./${script_name} --list

EOF
}

# ------------------------------------------------------------------------------
# Privilege and Dependency Verification
# ------------------------------------------------------------------------------
check_prerequisites() {
    # Check for required utilities
    local missing=()
    for tool in lsblk dd sync awk sed grep findmnt; do
        if ! command -v "${tool}" >/dev/null 2>&1; then
            missing+=("${tool}")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required utilities: ${missing[*]}"
        log_error "Please install required packages (coreutils, util-linux) and re-run."
        exit 1
    fi

    # Check root privileges
    if [ "$(id -u)" -ne 0 ]; then
        log_warn "Root privileges are required to write directly to block devices."
        if command -v sudo >/dev/null 2>&1; then
            log_info "Elevating permissions via sudo..."
            exec sudo "$0" "$@"
        else
            log_error "sudo is not installed. Please re-run this script as root."
            exit 1
        fi
    fi
}

# ------------------------------------------------------------------------------
# ISO Discovery and Validation
# ------------------------------------------------------------------------------
resolve_iso() {
    local candidate="$1"

    if [ -n "${candidate}" ]; then
        if [ ! -f "${candidate}" ]; then
            log_error "Specified ISO file does not exist: ${candidate}"
            exit 1
        fi
        ISO_PATH="$(cd "$(dirname "${candidate}")" && pwd)/$(basename "${candidate}")"
        return
    fi

    # Auto-detect in project directory or current directory
    local detected_isos=()
    while IFS= read -r f; do
        [ -n "$f" ] && detected_isos+=("$f")
    done < <(find "${PROJECT_ROOT}" "${PWD}" -maxdepth 2 -type f -name "BriskOS*.iso" 2>/dev/null | sort -u || true)

    if [ ${#detected_isos[@]} -eq 1 ]; then
        ISO_PATH="${detected_isos[0]}"
        log_info "Auto-detected BriskOS ISO: ${ISO_PATH}"
        return
    fi

    if [ ${#detected_isos[@]} -gt 1 ]; then
        echo -e "\n${COLOR_BOLD}Multiple BriskOS ISO images detected:${COLOR_RESET}"
        for i in "${!detected_isos[@]}"; do
            local size
            size="$(ls -lh "${detected_isos[$i]}" | awk '{print $5}')"
            echo -e "  [${COLOR_CYAN}$((i + 1))${COLOR_RESET}] ${detected_isos[$i]} (${size})"
        done
        echo ""
        read -r -p "Select ISO image [1-${#detected_isos[@]}]: " iso_choice
        if [[ "${iso_choice}" =~ ^[0-9]+$ ]] && [ "${iso_choice}" -ge 1 ] && [ "${iso_choice}" -le ${#detected_isos[@]} ]; then
            ISO_PATH="${detected_isos[$((iso_choice - 1))]}"
            return
        else
            log_error "Invalid selection. Exiting."
            exit 1
        fi
    fi

    # Prompt user for manual path
    echo ""
    read -r -p "Enter path to BriskOS ISO image: " manual_iso
    manual_iso="${manual_iso/#\~/$HOME}"
    if [ ! -f "${manual_iso}" ]; then
        log_error "File does not exist: ${manual_iso}"
        exit 1
    fi
    ISO_PATH="$(cd "$(dirname "${manual_iso}")" && pwd)/$(basename "${manual_iso}")"
}

validate_iso() {
    local size_bytes
    size_bytes="$(stat -c %s "${ISO_PATH}" 2>/dev/null || stat -f %z "${ISO_PATH}" 2>/dev/null || echo 0)"
    
    # ISO should be at least 100 MB
    if [ "${size_bytes}" -lt 104857600 ]; then
        log_error "Selected file is suspiciously small ($((size_bytes / 1024 / 1024)) MB): ${ISO_PATH}"
        log_error "A valid BriskOS ISO image must be at least 100 MB."
        exit 1
    fi

    local human_size
    human_size="$(ls -lh "${ISO_PATH}" | awk '{print $5}')"
    log_info "Selected Source ISO: ${COLOR_BOLD}${ISO_PATH}${COLOR_RESET} (${human_size})"
}

# ------------------------------------------------------------------------------
# Removable USB Discovery & Safety Filtering
# ------------------------------------------------------------------------------
# Populates global array USB_DEVICES with raw device names (e.g. sdb)
get_removable_usb_devices() {
    USB_DEVICES=()

    # Find root and boot device nodes to prevent any chance of selecting them
    local root_src boot_src root_disk="" boot_disk=""
    root_src="$(findmnt -n -o SOURCE / 2>/dev/null || true)"
    boot_src="$(findmnt -n -o SOURCE /boot 2>/dev/null || true)"

    if [ -n "${root_src}" ]; then
        root_disk="$(lsblk -n -o PKNAME "${root_src}" 2>/dev/null || true)"
        if [ -z "${root_disk}" ]; then
            root_disk="$(basename "${root_src}")"
        fi
    fi

    if [ -n "${boot_src}" ]; then
        boot_disk="$(lsblk -n -o PKNAME "${boot_src}" 2>/dev/null || true)"
        if [ -z "${boot_disk}" ]; then
            boot_disk="$(basename "${boot_src}")"
        fi
    fi

    # Query all block devices in pair format
    while IFS= read -r line; do
        [ -z "${line}" ] && continue

        local dev_name dev_size dev_model dev_tran dev_rm dev_hotplug dev_type dev_vendor dev_ro
        dev_name="$(echo "${line}" | sed -n 's/.*NAME="\([^"]*\)".*/\1/p')"
        dev_size="$(echo "${line}" | sed -n 's/.*SIZE="\([^"]*\)".*/\1/p')"
        dev_model="$(echo "${line}" | sed -n 's/.*MODEL="\([^"]*\)".*/\1/p')"
        dev_tran="$(echo "${line}" | sed -n 's/.*TRAN="\([^"]*\)".*/\1/p')"
        dev_rm="$(echo "${line}" | sed -n 's/.*RM="\([^"]*\)".*/\1/p')"
        dev_hotplug="$(echo "${line}" | sed -n 's/.*HOTPLUG="\([^"]*\)".*/\1/p')"
        dev_type="$(echo "${line}" | sed -n 's/.*TYPE="\([^"]*\)".*/\1/p')"
        dev_vendor="$(echo "${line}" | sed -n 's/.*VENDOR="\([^"]*\)".*/\1/p')"
        dev_ro="$(echo "${line}" | sed -n 's/.*RO="\([^"]*\)".*/\1/p')"

        # Only process whole disk devices
        [ "${dev_type}" != "disk" ] && continue
        # Ignore read-only devices (e.g. optical discs)
        [ "${dev_ro}" = "1" ] && continue

        # CRITICAL FILTER: Must be USB transport or Removable / Hotplug
        if [ "${dev_tran}" != "usb" ] && [ "${dev_rm}" != "1" ] && [ "${dev_hotplug}" != "1" ]; then
            continue
        fi

        # NEVER allow system disks hosting root or boot
        if [ "${dev_name}" = "${root_disk}" ] || [ "${dev_name}" = "${boot_disk}" ]; then
            continue
        fi

        # Disallow virtual and loop devices
        if [[ "${dev_name}" =~ ^(loop|zram|ram|dm-|sr|nbd) ]]; then
            continue
        fi

        # Disallow internal NVMe / SATA drives unless explicitly USB transport
        if [[ "${dev_name}" =~ ^nvme ]] && [ "${dev_tran}" != "usb" ]; then
            continue
        fi

        # Double check no child partition is mounted to critical system trees
        local mount_points
        mount_points="$(lsblk -n -o MOUNTPOINT "/dev/${dev_name}" 2>/dev/null | grep -v '^$' || true)"
        if echo "${mount_points}" | grep -Eq '^(/|/boot|/boot/efi|/home|/usr|/var|\[SWAP\])$'; then
            continue
        fi

        USB_DEVICES+=("${dev_name}")
    done < <(lsblk -d -n -P -o NAME,SIZE,MODEL,TRAN,RM,HOTPLUG,TYPE,VENDOR,RO 2>/dev/null || true)
}

list_usb_devices() {
    get_removable_usb_devices

    if [ ${#USB_DEVICES[@]} -eq 0 ]; then
        log_warn "No removable USB drives detected."
        echo -e "${COLOR_GRAY}Please plug in a USB flash drive and run this script again.${COLOR_RESET}"
        return
    fi

    echo -e "${COLOR_BOLD}Detected Removable USB Drives:${COLOR_RESET}"
    printf "${COLOR_GRAY}%-4s %-12s %-10s %-24s %-8s %-6s${COLOR_RESET}\n" "NUM" "DEVICE" "CAPACITY" "MODEL / VENDOR" "TRAN" "RM"
    echo "----------------------------------------------------------------------"

    for i in "${!USB_DEVICES[@]}"; do
        local dev="${USB_DEVICES[$i]}"
        local size model vendor tran rm
        size="$(lsblk -n -d -o SIZE "/dev/${dev}" 2>/dev/null || echo "N/A")"
        model="$(lsblk -n -d -o MODEL "/dev/${dev}" 2>/dev/null || echo "")"
        vendor="$(lsblk -n -d -o VENDOR "/dev/${dev}" 2>/dev/null || echo "")"
        tran="$(lsblk -n -d -o TRAN "/dev/${dev}" 2>/dev/null || echo "N/A")"
        rm="$(lsblk -n -d -o RM "/dev/${dev}" 2>/dev/null || echo "N/A")"

        local full_desc="${vendor} ${model}"
        full_desc="$(echo "${full_desc}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        [ -z "${full_desc}" ] && full_desc="Generic USB Storage"

        printf " [%d] %-12s %-10s %-24s %-8s %-6s\n" \
            "$((i + 1))" "/dev/${dev}" "${size}" "${full_desc:0:23}" "${tran}" "${rm}"
    done
    echo "----------------------------------------------------------------------"
}

# ------------------------------------------------------------------------------
# Target Device Selection & Comprehensive Safety Check
# ------------------------------------------------------------------------------
select_target_device() {
    local preselected="$1"

    get_removable_usb_devices

    if [ ${#USB_DEVICES[@]} -eq 0 ]; then
        log_error "No removable USB drives detected."
        log_error "Please plug in a USB flash drive and try again."
        exit 1
    fi

    if [ -n "${preselected}" ]; then
        TARGET_DEV="$(basename "${preselected}")"
    else
        list_usb_devices
        echo ""
        read -r -p "Select target USB drive [1-${#USB_DEVICES[@]}] or enter device name (e.g. sdb): " user_input
        user_input="$(echo "${user_input}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

        if [[ "${user_input}" =~ ^[0-9]+$ ]] && [ "${user_input}" -ge 1 ] && [ "${user_input}" -le ${#USB_DEVICES[@]} ]; then
            TARGET_DEV="${USB_DEVICES[$((user_input - 1))]}"
        else
            TARGET_DEV="$(basename "${user_input}")"
        fi
    fi
}

verify_target_safety() {
    local dev_node="/dev/${TARGET_DEV}"

    # 1. Existence check
    if [ ! -b "${dev_node}" ]; then
        log_error "Target block device '${dev_node}' does not exist!"
        exit 1
    fi

    # 2. Block device type check
    local dev_type
    dev_type="$(lsblk -n -d -o TYPE "${dev_node}" 2>/dev/null || echo "")"
    if [ "${dev_type}" != "disk" ]; then
        log_error "Target '${dev_node}' is not a whole disk (detected type: '${dev_type}')."
        log_error "You must flash to the entire disk (e.g. /dev/sdb), not a single partition (e.g. /dev/sdb1)."
        exit 1
    fi

    # 3. Read-only check
    local dev_ro
    dev_ro="$(lsblk -n -d -o RO "${dev_node}" 2>/dev/null || echo "0")"
    if [ "${dev_ro}" = "1" ]; then
        log_error "Target '${dev_node}' is a read-only device. Write operation cannot proceed."
        exit 1
    fi

    # 4. Strict Transport and Removable check
    local dev_tran dev_rm dev_hotplug
    dev_tran="$(lsblk -n -d -o TRAN "${dev_node}" 2>/dev/null || echo "")"
    dev_rm="$(lsblk -n -d -o RM "${dev_node}" 2>/dev/null || echo "")"
    dev_hotplug="$(lsblk -n -d -o HOTPLUG "${dev_node}" 2>/dev/null || echo "")"

    if [ "${dev_tran}" != "usb" ] && [ "${dev_rm}" != "1" ] && [ "${dev_hotplug}" != "1" ]; then
        echo -e "\n${COLOR_RED}${COLOR_BOLD}======================================================================${COLOR_RESET}"
        echo -e "${COLOR_RED}${COLOR_BOLD}                 CRITICAL SAFETY VIOLATION PREVENTED                  ${COLOR_RESET}"
        echo -e "${COLOR_RED}${COLOR_BOLD}======================================================================${COLOR_RESET}"
        log_error "Target device '${dev_node}' is NOT a removable USB flash drive!"
        log_error "Detected Transport: '${dev_tran}', Removable: '${dev_rm}', Hotplug: '${dev_hotplug}'"
        log_error "This appears to be an internal SATA, NVMe, or system disk."
        log_error "To protect your operating system and data, writing is STRICTLY PROHIBITED."
        echo -e "${COLOR_RED}${COLOR_BOLD}======================================================================${COLOR_RESET}\n"
        exit 1
    fi

    # 5. Check against active root and system mount points
    local root_src boot_src
    root_src="$(findmnt -n -o SOURCE / 2>/dev/null || true)"
    boot_src="$(findmnt -n -o SOURCE /boot 2>/dev/null || true)"
    local root_disk="" boot_disk=""
    [ -n "${root_src}" ] && root_disk="$(lsblk -n -o PKNAME "${root_src}" 2>/dev/null || basename "${root_src}")"
    [ -n "${boot_src}" ] && boot_disk="$(lsblk -n -o PKNAME "${boot_src}" 2>/dev/null || basename "${boot_src}")"

    if [ "${TARGET_DEV}" = "${root_disk}" ] || [ "${TARGET_DEV}" = "${boot_disk}" ]; then
        log_error "FATAL: Target device '${dev_node}' is the host system disk! Aborting immediately."
        exit 1
    fi

    # Check all mounted child partitions
    local mounts
    mounts="$(lsblk -n -o MOUNTPOINT "${dev_node}" 2>/dev/null | grep -v '^$' || true)"
    if echo "${mounts}" | grep -Eq '^(/|/boot|/boot/efi|/home|/usr|/var|\[SWAP\])$'; then
        log_error "FATAL: Device '${dev_node}' hosts vital system filesystems (${mounts}). Write refused."
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# Unmount Active Partitions on Target USB Drive
# ------------------------------------------------------------------------------
unmount_target_partitions() {
    local dev_node="/dev/${TARGET_DEV}"
    local mounted_parts=()

    while IFS= read -r part; do
        [ -n "${part}" ] && mounted_parts+=("${part}")
    done < <(lsblk -n -o PATH,MOUNTPOINT "${dev_node}" 2>/dev/null | awk '$2 != "" {print $1}' || true)

    if [ ${#mounted_parts[@]} -gt 0 ]; then
        log_info "Unmounting active partitions on ${dev_node}..."
        for part in "${mounted_parts[@]}"; do
            log_info "  Unmounting ${part}..."
            umount "${part}" 2>/dev/null || umount -l "${part}" 2>/dev/null || {
                log_error "Failed to unmount ${part}. Please close any file managers or terminals using it."
                exit 1
            }
        done
        log_success "All partitions unmounted successfully."
    fi
}

# ------------------------------------------------------------------------------
# Explicit Typed Confirmation & Flash Execution
# ------------------------------------------------------------------------------
confirm_and_flash() {
    local dev_node="/dev/${TARGET_DEV}"
    local dev_size dev_model dev_vendor
    dev_size="$(lsblk -n -d -o SIZE "${dev_node}" 2>/dev/null || echo "Unknown")"
    dev_model="$(lsblk -n -d -o MODEL "${dev_node}" 2>/dev/null || echo "")"
    dev_vendor="$(lsblk -n -d -o VENDOR "${dev_node}" 2>/dev/null || echo "")"
    local full_desc="${dev_vendor} ${dev_model}"
    full_desc="$(echo "${full_desc}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -z "${full_desc}" ] && full_desc="USB Flash Drive"

    local iso_size
    iso_size="$(ls -lh "${ISO_PATH}" | awk '{print $5}')"

    echo ""
    echo -e "${COLOR_YELLOW}${COLOR_BOLD}======================================================================${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}${COLOR_BOLD}                 WARNING: DESTRUCTIVE WRITE OPERATION                 ${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}${COLOR_BOLD}======================================================================${COLOR_RESET}"
    echo -e " Source ISO:     ${COLOR_CYAN}${ISO_PATH}${COLOR_RESET} (${iso_size})"
    echo -e " Target Device:  ${COLOR_RED}${COLOR_BOLD}${dev_node}${COLOR_RESET} (${full_desc})"
    echo -e " Target Size:    ${COLOR_BOLD}${dev_size}${COLOR_RESET}"
    echo ""
    echo -e " ${COLOR_RED}${COLOR_BOLD}ALL EXISTING DATA, PARTITIONS, AND FILESYSTEMS ON ${dev_node}"
    echo -e " WILL BE PERMANENTLY AND IRREVERSIBLY ERASED!${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}${COLOR_BOLD}======================================================================${COLOR_RESET}"
    echo ""
    echo -e "To proceed with flashing, type the target device name '${COLOR_BOLD}${TARGET_DEV}${COLOR_RESET}' exactly."
    echo -e "Type anything else or press Ctrl+C to safely cancel."
    echo ""
    
    read -r -p "Confirmation [type '${TARGET_DEV}']: " confirmation
    confirmation="$(echo "${confirmation}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

    if [ "${confirmation}" != "${TARGET_DEV}" ] && [ "${confirmation}" != "${dev_node}" ]; then
        log_warn "Confirmation mismatch ('${confirmation}' != '${TARGET_DEV}')."
        log_info "Operation aborted. Zero changes have been made to any storage devices."
        exit 0
    fi

    echo ""
    log_info "Starting raw block image write: ${ISO_PATH} -> ${dev_node}..."
    echo -e "${COLOR_GRAY}Writing blocks (4M block size, direct synchronization)...${COLOR_RESET}\n"

    # Execute dd with progress reporting and synchronous writes
    if dd if="${ISO_PATH}" of="${dev_node}" bs=4M status=progress oflag=sync conv=fsync; then
        echo ""
        log_info "Flushing operating system disk buffers..."
        sync
        log_success "Kernel write buffers flushed."

        # Inform kernel of partition table change
        blockdev --rereadpt "${dev_node}" 2>/dev/null || partprobe "${dev_node}" 2>/dev/null || true

        echo ""
        echo -e "${COLOR_GREEN}${COLOR_BOLD}======================================================================${COLOR_RESET}"
        echo -e "${COLOR_GREEN}${COLOR_BOLD}                   FLASH OPERATION COMPLETE!                          ${COLOR_RESET}"
        echo -e "${COLOR_GREEN}${COLOR_BOLD}======================================================================${COLOR_RESET}"
        echo -e " BriskOS 1.0 (Feather) bootable media has been successfully written to:"
        echo -e " ${COLOR_BOLD}${dev_node}${COLOR_RESET}"
        echo ""
        echo -e " You can now safely remove the USB drive and boot your computer."
        echo -e " Consult ${COLOR_CYAN}INSTALL.md${COLOR_RESET} for BIOS/UEFI boot menu keys and setup guide."
        echo -e "${COLOR_GREEN}${COLOR_BOLD}======================================================================${COLOR_RESET}\n"
    else
        log_error "Write operation failed during dd execution."
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# Main Entry Point & Argument Parsing
# ------------------------------------------------------------------------------
main() {
    local cli_iso=""
    local cli_device=""
    local list_only=false

    while [ $# -gt 0 ]; do
        case "$1" in
            -i|--iso)
                cli_iso="$2"
                shift 2
                ;;
            -d|--device)
                cli_device="$2"
                shift 2
                ;;
            -l|--list)
                list_only=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                if [ -z "${cli_iso}" ] && [[ "$1" =~ \.iso$ ]]; then
                    cli_iso="$1"
                    shift
                else
                    log_error "Unknown argument: $1"
                    show_usage
                    exit 1
                fi
                ;;
        esac
    done

    print_banner

    # List only mode does not need root or ISO
    if [ "${list_only}" = true ]; then
        list_usb_devices
        exit 0
    fi

    check_prerequisites "$@"
    resolve_iso "${cli_iso}"
    validate_iso
    select_target_device "${cli_device}"
    verify_target_safety
    unmount_target_partitions
    confirm_and_flash
}

main "$@"

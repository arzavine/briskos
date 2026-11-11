# BriskOS 1.0 LTS (Feather) - Installation Manual

This manual provides authoritative, step-by-step instructions for flashing, booting, testing, and installing **BriskOS 1.0 LTS (Feather)** on bare-metal hardware.

---

## Table of Contents

1. [System Requirements](#1-system-requirements)
2. [Preparing Bootable USB Media](#2-preparing-bootable-usb-media)
   - [2.1 Preparation on Windows](#21-preparation-on-windows)
   - [2.2 Preparation on Linux](#22-preparation-on-linux)
   - [2.3 Preparation on macOS](#23-preparation-on-macos)
3. [BIOS / UEFI Firmware Setup](#3-bios--uefi-firmware-setup)
   - [3.1 Motherboard & OEM Boot Menu Keys](#31-motherboard--oem-boot-menu-keys)
   - [3.2 UEFI vs Legacy BIOS Configuration](#32-uefi-vs-legacy-bios-configuration)
   - [3.3 Secure Boot Guidance](#33-secure-boot-guidance)
   - [3.4 Windows Fast Startup & BitLocker Notice](#34-windows-fast-startup--bitlocker-notice)
4. [Live Session Hardware Verification](#4-live-session-hardware-verification)
   - [4.1 Non-Destructive Environment](#41-non-destructive-environment)
   - [4.2 Display & Wayland Compositor](#42-display--wayland-compositor)
   - [4.3 Wi-Fi & Network Configuration](#43-wi-fi--network-configuration)
   - [4.4 Audio Playback & Volume Control](#44-audio-playback--volume-control)
5. [Installation Walkthrough](#5-installation-walkthrough)
   - [5.1 Strategy A: Clean Drive Installation](#51-strategy-a-clean-drive-installation)
   - [5.2 Strategy B: Dual-Boot alongside Windows](#52-strategy-b-dual-boot-alongside-windows)
   - [5.3 Disk Partition Layout Reference](#53-disk-partition-layout-reference)
6. [Post-Installation Configuration](#6-post-installation-configuration)
   - [6.1 Package Repository & System Updates](#61-package-repository--system-updates)
   - [6.2 Windows Compatibility Layer (Wine)](#62-windows-compatibility-layer-wine)
   - [6.3 Office Font Compatibility Verification](#63-office-font-compatibility-verification)
   - [6.4 Keyboard Shortcut Cheat Sheet](#64-keyboard-shortcut-cheat-sheet)
   - [6.5 Dual-Boot Hardware Clock Fix (RTC UTC)](#65-dual-boot-hardware-clock-fix-rtc-utc)
7. [Troubleshooting & FAQ](#7-troubleshooting--faq)

---

## 1. System Requirements

BriskOS 1.0 LTS is engineered to run with ultra-low resource utilization without compromising on modern Wayland desktop capabilities.

| Component | Minimum Specification (Functional) | Recommended Specification (Optimal) |
| :--- | :--- | :--- |
| **Processor** | 1.0 GHz x86_64 (64-bit AMD/Intel) | 2.0+ GHz Dual-Core or Quad-Core x86_64 |
| **System Memory (RAM)** | 1.0 GB physical RAM | 2.0+ GB physical RAM |
| **Storage Capacity** | 16 GB disk space (HDD or SSD) | 32+ GB Solid State Drive (NVMe or SATA SSD) |
| **Graphics Controller** | VGA-compatible (800x600 resolution) | Intel HD/UHD, AMD Radeon (amdgpu), or NVIDIA |
| **Boot Firmware** | Standard BIOS (MBR) or UEFI (GPT) | 64-bit UEFI with GPT partition table |
| **Installation Media** | 4 GB USB 2.0 flash drive | 8 GB USB 3.0+ flash drive |

> [!NOTE]
> BriskOS automatically initializes **zstd zram compressed swap** (50% RAM allocation) on boot. This delivers fluid multitasking on systems with as little as 1 GB of physical memory.

---

## 2. Preparing Bootable USB Media

Before flashing, obtain the official ISO image (`BriskOS-1.0-amd64.iso`) and verify its SHA256 integrity:

```bash
# Linux / macOS
sha256sum -c BriskOS-1.0-amd64.iso.sha256

# Windows PowerShell
Get-FileHash .\BriskOS-1.0-amd64.iso -Algorithm SHA256
```

### 2.1 Preparation on Windows

#### Option A: Rufus (Recommended Standalone Flasher)
1. Download **Rufus** (portable executable) from [https://rufus.ie](https://rufus.ie).
2. Insert a USB flash drive (minimum 4 GB capacity).
3. Under **Device**, select your USB flash drive.
4. Under **Boot selection**, click **SELECT** and browse to `BriskOS-1.0-amd64.iso`.
5. Set **Partition scheme** to:
   - **GPT** if your target computer supports UEFI (recommended for hardware built after 2012).
   - **MBR** if targeting older legacy BIOS hardware.
6. Set **Target system** to **UEFI (non CSM)** or **BIOS (or UEFI-CSM)**.
7. Click **START**.
8. When prompted with **ISOHybrid image detected**, select **Write in ISO Image mode (Recommended)** and click **OK**.
9. Confirm the data destruction prompt. Wait for the status indicator to display **READY**.

#### Option B: Ventoy (Multi-Boot USB — Drag & Drop)
1. Download **Ventoy** from [https://www.ventoy.net](https://www.ventoy.net).
2. Extract the archive and launch `Ventoy2Disk.exe`.
3. Select your USB drive and click **Install**.
4. Once installation completes, open the newly labeled `Ventoy` drive in Windows File Explorer.
5. Drag and drop `BriskOS-1.0-amd64.iso` directly onto the USB drive. No image extraction or re-flashing is required.

#### Option C: BalenaEtcher (Simple 3-Step Flasher)
1. Download **BalenaEtcher** from [https://etcher.balena.io](https://etcher.balena.io).
2. Click **Flash from file** and pick `BriskOS-1.0-amd64.iso`.
3. Click **Select target** and mark your USB flash drive.
4. Click **Flash!** and approve Windows UAC elevation.

---

### 2.2 Preparation on Linux

#### Option A: BriskOS Safe USB Flash Utility (Recommended)
BriskOS includes an automated USB writer equipped with strict safety checks that prevent accidental overwriting of internal SATA or NVMe drives:

```bash
git clone https://github.com/briskos/briskos.git
cd briskos
chmod +x scripts/flash-usb.sh
sudo ./scripts/flash-usb.sh --iso /path/to/BriskOS-1.0-amd64.iso
```

**Workflow:**
1. The script audits connected block devices and lists only removable USB storage.
2. It validates that the selected drive is non-internal (`TRAN=usb` or `RM=1`).
3. It unmounts active partitions on the target drive automatically.
4. It requires explicit typed confirmation of the target device node (e.g. `sdb`) before executing `dd` with direct synchronization (`oflag=sync`).

#### Option B: Ventoy on Linux
```bash
tar -xf ventoy-*.tar.gz
cd ventoy-*
# Replace /dev/sdX with your USB drive node (e.g., /dev/sdb)
sudo ./Ventoy2Disk.sh -i /dev/sdX
# Mount the Ventoy partition and copy ISO
cp /path/to/BriskOS-1.0-amd64.iso /media/$USER/Ventoy/
```

#### Option C: Native `dd` Command
```bash
# 1. Identify your USB drive node (e.g., /dev/sdb):
lsblk -d -o NAME,SIZE,MODEL,TRAN,RM

# 2. Write image directly (replace /dev/sdX with your USB node):
sudo dd if=BriskOS-1.0-amd64.iso of=/dev/sdX bs=4M status=progress oflag=sync conv=fsync
sudo sync
```

> [!CAUTION]
> Always verify that `/dev/sdX` references the USB drive and **never** your system disk (`/dev/sda`, `/dev/nvme0n1`). Running `dd` against the wrong disk will instantly erase all data.

---

### 2.3 Preparation on macOS

1. Insert USB drive and identify its disk identifier:
   ```bash
   diskutil list
   ```
2. Unmount the disk (replace `N` with your disk number, e.g. `disk3`):
   ```bash
   diskutil unmountDisk /dev/diskN
   ```
3. Write image using raw disk access (`rdiskN` offers higher throughput):
   ```bash
   sudo dd if=BriskOS-1.0-amd64.iso of=/dev/rdiskN bs=4m status=progress
   sudo sync
   ```

---

## 3. BIOS / UEFI Firmware Setup

### 3.1 Motherboard & OEM Boot Menu Keys

Insert your prepared USB drive into a direct motherboard port (avoid unpowered USB hubs). Power on the machine and immediately press the corresponding Boot Menu key:

| Manufacturer | Boot Menu Key | BIOS / UEFI Setup Key | Notes & Instructions |
| :--- | :--- | :--- | :--- |
| **Lenovo** (ThinkPad, IdeaPad) | `F12` | `F1` or `Enter` | ThinkPads: tap `Enter` at the splash screen to pause and access boot selection. IdeaPads: use the Novo pinhole button if `F12` is unresponsive. |
| **Dell** (XPS, Latitude, Inspiron) | `F12` | `F2` | Tap repeatedly immediately after pressing the power button. |
| **HP** (EliteBook, Pavilion, Envy) | `F9` | `Esc` then `F10` | Tap `Esc` on startup to trigger the Startup Menu, then press `F9` for Boot Options. |
| **ASUS** (ROG, ZenBook, Motherboards) | `F8` or `Esc` | `F2` or `Delete` | Laptops typically use `Esc`; desktop motherboards typically use `F8`. |
| **Acer** (Aspire, Swift, Predator) | `F12` | `F2` | If `F12` does not respond, enter BIOS (`F2`), navigate to the *Main* tab, and set *F12 Boot Menu* to **Enabled**. |
| **MSI** (Laptops & Motherboards) | `F11` | `Delete` | Tap `F11` continuously from cold boot. |
| **Gigabyte / Aorus** | `F12` | `Delete` | Desktop motherboards and laptops. |
| **Apple Mac (Intel x86_64)** | Hold `Option` (`Alt`) | N/A | Hold down the `Option` (`Alt`) key immediately after the startup chime until the boot picker appears. |
| **Microsoft Surface** | `Vol Down` + `Power` | `Vol Up` + `Power` | Hold Volume Down, press & release Power, release Volume Down when the Surface logo appears. |

---

### 3.2 UEFI vs Legacy BIOS Configuration

1. **Storage Controller**: Ensure storage mode is set to **AHCI** (disable Intel RST / VMD / RAID modes, which prevent standard Linux kernels from recognizing NVMe and SATA disks).
2. **Boot Mode**: Select **UEFI Mode** (recommended) or **CSM / Legacy Mode** for legacy hardware.
3. **USB Boot**: Ensure USB boot support is enabled in BIOS settings.

---

### 3.3 Secure Boot Guidance

BriskOS 1.0 is built on Debian Bookworm and includes upstream Microsoft-signed shim bootloaders (`grub-efi-amd64-signed`).

- **Standard Scenario**: BriskOS boots successfully with Secure Boot **Enabled**.
- **Alternative / Custom Firmware**: If your UEFI firmware blocks boot with a `Security Violation` or `Invalid Signature` message:
  1. Reboot and enter UEFI Setup (e.g. `F2`, `Del`, or `F10`).
  2. Locate the **Security** or **Boot** tab.
  3. Set **Secure Boot** to **Disabled**.
  4. Save settings and restart (`F10`).

---

### 3.4 Windows Fast Startup & BitLocker Notice

Before installing BriskOS alongside Windows:

1. **Disable Windows Fast Startup**:
   - Fast Startup locks Windows NTFS partitions in a semi-hibernated state, making them read-only and unshrinkable from Linux.
   - In Windows: Open **Control Panel** -> **Power Options** -> Click **Choose what the power buttons do** -> Click **Change settings that are currently unavailable** -> Uncheck **Turn on fast startup (recommended)** -> Click **Save changes**.
2. **Backup BitLocker Recovery Key**:
   - If Windows BitLocker device encryption is enabled on your drive, retrieve your 48-digit BitLocker recovery key at [https://account.microsoft.com/devices/recoverykey](https://account.microsoft.com/devices/recoverykey) before resizing partitions or modifying EFI bootloader entries.

---

## 4. Live Session Hardware Verification

### 4.1 Non-Destructive Environment

When BriskOS boots, it loads directly into a fully functioning Live Wayland desktop session operating completely within system RAM and a read-only squashfs image.

- **Zero Disk Writes**: No changes are made to your hard drives or SSDs while exploring the live session.
- **Default Credentials**:
  - Username: `user` (auto-logged in)
  - Password: `live`
  - Sudo: Unrestricted passwordless administrative access (`sudo su -`).

```
 +-----------------------------------------------------------------------+
 |                         BriskOS 1.0 (Feather)                         |
 |  Labwc Wayland Compositor | Sub-512 MB Idle RAM | Waybar Taskbar     |
 +-----------------------------------------------------------------------+
```

---

### 4.2 Display & Wayland Compositor

BriskOS uses the **Labwc** Wayland stacking compositor with server-side decorations and native hardware scaling.

- **Start Menu**: Click the feather icon on the left of the bottom taskbar or press the `Super` (Windows) key to launch the **Wofi** search menu.
- **Resolution & Multi-Monitor**: If your display resolution is not detected automatically, launch the terminal (`Super + Enter`) and inspect display connectors:
  ```bash
  wlr-randr
  ```
- **Terminal Emulator**: Press `Super + Enter` to open **Foot** (hardware-accelerated, high-performance terminal).

---

### 4.3 Wi-Fi & Network Configuration

Debian Bookworm non-free firmware (`firmware-iwlwifi`, `firmware-realtek`, `firmware-atheros`) is pre-installed.

1. **Graphical Connection**:
   - Click the Network icon in the Waybar taskbar tray (bottom right).
   - Select your wireless SSID and enter your WPA2/WPA3 password.
2. **Terminal / TUI Method**:
   - Open Foot (`Super + Enter`) and launch NetworkManager Text User Interface:
     ```bash
     nmtui
     ```
   - Navigate to **Activate a connection**, choose your network, and press Enter.

---

### 4.4 Audio Playback & Volume Control

BriskOS routes system audio through **PipeWire** and the **WirePlumber** session manager.

1. Test audio output from the terminal:
   ```bash
   speaker-test -t wav -c 2
   ```
2. Open the Volume Control mixer (`pavucontrol`):
   - Click the Volume module in the Waybar taskbar or run:
     ```bash
     pavucontrol
     ```
   - In the **Output Devices** tab, verify that your speakers or headphones are selected as fallback output.

---

## 5. Installation Walkthrough

### 5.1 Strategy A: Clean Drive Installation

This procedure allocates the entire storage drive exclusively to BriskOS, wiping all existing data and operating systems.

```text
Target Disk Layout (Clean Install, GPT):
+-------------------------+----------------------------------------------+
| ESP Partition (512 MB)  | Root Ext4 Filesystem (Remaining Disk Space)  |
| /boot/efi (FAT32)       | / (ext4)                                     |
+-------------------------+----------------------------------------------+
```

**Step-by-step:**
1. Back up all essential personal files from the target drive to external storage.
2. Boot into the BriskOS live session.
3. Launch the graphical installer from the desktop or Start Menu ("Install BriskOS").
4. Select your language, keyboard layout, and timezone.
5. In the Partitioning step, select **Erase disk**.
6. (Optional) Choose whether to enable swap file (zram compressed swap is already active by default).
7. Enter your user account details and root password.
8. Review the summary screen and click **Install**.
9. Once installation finishes, click **Restart Now** and unplug the USB drive when prompted.

---

### 5.2 Strategy B: Dual-Boot alongside Windows

Dual-booting allows you to select either Windows 10/11 or BriskOS from the GRUB boot menu upon powering on your PC.

```text
Dual-Boot Disk Layout (Preserving Windows, GPT):
+---------------+---------------------+---------------+--------------------------+
| Windows ESP   | Microsoft Reserved  | Windows C:    | BriskOS Root Filesystem  |
| /boot/efi     | 16 MB               | NTFS          | / (ext4, >= 20 GB)       |
| (100-260 MB)  |                     |               |                          |
+---------------+---------------------+---------------+--------------------------+
```

#### Step 1: Shrink Windows Partition
1. Boot into Windows.
2. Press `Win + X` and select **Disk Management** (`diskmgmt.msc`).
3. Right-click your main Windows volume (usually `C:`) and select **Shrink Volume**.
4. Enter the amount of space to shrink in MB (minimum `20480` for 20 GB; recommended `40960` for 40 GB).
5. Click **Shrink**. The unallocated space will appear as black unpartitioned space.
6. Restart and boot from your BriskOS USB drive.

#### Step 2: Install BriskOS in Free Space
1. In the BriskOS installer, select **Install alongside Windows Boot Manager** or **Manual Partitioning**:
   - If using **Manual Partitioning**:
     - Locate the existing **EFI System Partition** (FAT32, ~100–260 MB). Set its mount point to `/boot/efi`. **Do NOT format it!**
     - Select the **Free Space** created in Step 1.
     - Create a new partition:
       - Type: `ext4`
       - Mount Point: `/`
       - Size: Use all available free space.
2. Proceed through user setup and complete the installation.
3. During bootloader setup, the installer runs `os-prober`, which discovers the Windows Boot Manager on the EFI partition and automatically adds a `Windows Boot Manager` entry to the GRUB menu.

---

### 5.3 Disk Partition Layout Reference

| Partition | Recommended Size | Filesystem | Mount Point | Flags / Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **EFI System Partition** | 512 MB (or 100-260 MB existing) | `FAT32` (`vfat`) | `/boot/efi` | `boot`, `esp` (Required for UEFI) |
| **Root Filesystem** | 20+ GB | `ext4` | `/` | System files, `/home`, applications |
| **Virtual Swap** | Dynamically managed in RAM | `zram` (zstd) | `[SWAP]` | Automated via `zram-tools` (50% RAM) |

---

## 6. Post-Installation Configuration

### 6.1 Package Repository & System Updates

Keep your system packages current and security patches up to date.

- **Graphical Updater**:
  - BriskOS includes a lightweight Zenity graphical updater.
  - Launch it anytime from the Start Menu: **System -> Software Updater** (`brisk-updater-gui`).
  - An autostart daemon (`brisk-update-checker`) periodically checks for upstream BriskOS releases and notifies you when an update is available.
- **Command Line Updater**:
  ```bash
  sudo apt update
  sudo apt upgrade -y
  ```

---

### 6.2 Windows Compatibility Layer (Wine)

BriskOS includes an out-of-the-box Windows application runtime:

1. **Double-Click Execution**:
   - Download or transfer any `.exe` (standalone application or installer) or `.msi` package.
   - Open **Thunar** file manager and double-click the file.
   - BriskOS Wine Runner (`brisk-wine-runner`) automatically configures a 64-bit Wine prefix (`~/.wine`) and launches the application.
2. **Wine Control Panel**:
   - Launch **Wine Configuration** (`brisk-wine-config`) from the Start Menu to access:
     - Windows Version Selector (`winecfg`): Switch between Windows 10, Windows 7, or XP modes.
     - Component Manager (`winetricks`): Install DirectX, .NET Framework, or Visual C++ runtimes.
     - Prefix Maintenance: Clean reset of the Wine environment if needed.

---

### 6.3 Office Font Compatibility Verification

BriskOS eliminates font mismatch and document reformatting through Fontconfig metric aliases:

| Microsoft Font Requested | BriskOS Metric Substitute | Target Application |
| :--- | :--- | :--- |
| **Calibri** | Carlito / Liberation Sans | Word processing & spreadsheets |
| **Cambria** | Caladea / Liberation Serif | Academic papers & reports |
| **Arial** | Liberation Sans / Arimo | General presentations & web |
| **Times New Roman** | Liberation Serif / Tinos | Standard documents & legal forms |
| **Courier New** | Liberation Mono / Cousine | Monospace code & plain text |

Test font substitution resolution in the terminal:
```bash
fc-match "Calibri"
# Expected output: Carlito-Regular.ttf: "Carlito" "Regular"

fc-match "Times New Roman"
# Expected output: LiberationSerif-Regular.ttf: "Liberation Serif" "Regular"
```

---

### 6.4 Keyboard Shortcut Cheat Sheet

BriskOS uses standardized desktop keybindings configured in Labwc (`rc.xml`):

| Shortcut Key | Action | Description |
| :--- | :--- | :--- |
| `Super` *(Windows Key)* | Toggle Start Menu | Launches or closes the Wofi application search menu |
| `Super` + `Enter` | Launch Terminal | Opens the Foot Wayland terminal |
| `Super` + `E` | Open File Manager | Launches Thunar file manager |
| `Alt` + `F4` | Close Window | Gracefully closes the focused application |
| `Alt` + `Tab` | Switch Windows | Cycles forward through running application windows |
| `Alt` + `Shift` + `Tab` | Switch Windows (Reverse) | Cycles backward through running application windows |
| `Super` + `Left Arrow` | Snap Window Left | Tiles window to the left half of the display |
| `Super` + `Right Arrow` | Snap Window Right | Tiles window to the right half of the display |
| `Super` + `Up Arrow` | Maximize Window | Toggles window maximization |
| `Super` + `Down Arrow` | Minimize Window | Iconifies window to the Waybar taskbar |
| `Super` + `Shift` + `Up` | Toggle Fullscreen | Sets window to borderless fullscreen |
| `Super` + `L` | Lock Session | Locks screen securely with swaylock |
| `Super` + `Shift` + `C` | Reload Compositor | Hot-reloads Labwc desktop configuration without logout |
| `Alt` + `Space` | Client Actions Menu | Displays window operations menu (Move, Resize, Shade) |
| `Right-Click Desktop` | Openbox Root Menu | Access quick applications, tools, and system controls |

---

### 6.5 Dual-Boot Hardware Clock Fix (RTC UTC)

Windows stores local time in the motherboard Real-Time Clock (RTC), whereas Linux defaults to Coordinated Universal Time (UTC). This can cause the clock in Windows to shift by several hours after booting into Linux.

To synchronize both operating systems seamlessly, set Linux to maintain the hardware clock in local time:

```bash
timedatectl set-local-rtc 1 --adjust-system-clock
```

Verify the clock status:
```bash
timedatectl status
# Ensure "RTC in local TZ: yes" is displayed.
```

---

## 7. Troubleshooting & FAQ

### Q1: The screen goes black or freezes immediately after selecting "Live System" in GRUB.
- **Cause**: Incompatible GPU kernel modesetting with specific legacy NVIDIA or hybrid graphics.
- **Solution**:
  1. Restart the machine and enter the GRUB boot menu.
  2. Highlight the first boot entry and press `e` to edit commands.
  3. Locate the line beginning with `linux /live/vmlinuz...`.
  4. Append ` nomodeset` to the end of that line.
  5. Press `Ctrl + X` or `F10` to boot with basic framebuffer fallback.

---

### Q2: The USB flash drive is not visible in the UEFI Boot Menu.
- **Solution**:
  - Re-flash the USB drive using **Rufus** with Partition Scheme set to **GPT** and Target System set to **UEFI**.
  - Plug the USB drive into a USB 2.0 port (black port) directly on the rear I/O shield of desktop PCs.
  - Disable **Fast Boot** in your UEFI firmware settings.

---

### Q3: Wi-Fi device is not detected.
- **Solution**:
  1. Open Foot (`Super + Enter`) and check kernel hardware discovery:
     ```bash
     lspci -nnk | grep -iA3 net
     ```
  2. Check for missing firmware requests in the system log:
     ```bash
     sudo dmesg | grep -i firmware
     ```
  3. If your adapter requires proprietary Broadcom drivers:
     ```bash
     sudo apt update
     sudo apt install broadcom-sta-dkms
     sudo modprobe wl
     ```

---

### Q4: How do I restore the Windows Bootloader if GRUB was accidentally overwritten?
- **Solution**:
  1. Boot from a standard Windows 10/11 Installation USB.
  2. On the installation screen, select **Repair your computer** -> **Troubleshoot** -> **Command Prompt**.
  3. Execute:
     ```cmd
     bootrec /fixboot
     bootrec /rebuildbcd
     ```
  4. Reboot into Windows.

---

*BriskOS Project Documentation — Engineered for speed, efficiency, and clarity.*

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
   - [5.1 Launching the Calamares Installer](#51-launching-the-calamares-installer)
   - [5.2 Method 2: Permanent Installation via Calamares GUI Installer](#52-method-2-permanent-installation-via-calamares-gui-installer)
     - [Step 1: Welcome & Pre-Flight Validation](#step-1-welcome--pre-flight-validation)
     - [Step 2: Regional Localization (Locale & Timezone)](#step-2-regional-localization-locale--timezone)
     - [Step 3: Keyboard Model & Keymap Selection](#step-3-keyboard-model--keymap-selection)
     - [Step 4: Disk Partitioning (Erase Disk vs Manual Partitioning)](#step-4-disk-partitioning-erase-disk-vs-manual-partitioning)
     - [Step 5: User Account & Authentication Setup](#step-5-user-account--authentication-setup)
     - [Step 6: Installation Summary Review](#step-6-installation-summary-review)
     - [Step 7: Automated Installation & Unsquashfs Extraction](#step-7-automated-installation--unsquashfs-extraction)
     - [Step 8: Bootloader Deployment & Live Package Removal](#step-8-bootloader-deployment--live-package-removal)
     - [Step 9: Reboot into BriskOS](#step-9-reboot-into-briskos)
   - [5.3 Strategy A: Clean Drive Installation](#53-strategy-a-clean-drive-installation)
   - [5.4 Strategy B: Dual-Boot alongside Windows](#54-strategy-b-dual-boot-alongside-windows)
   - [5.5 Disk Partition Layout Reference](#55-disk-partition-layout-reference)
6. [Post-Installation Configuration](#6-post-installation-configuration)
   - [6.1 Package Repository & System Updates](#61-package-repository--system-updates)
   - [6.2 Windows Compatibility Layer (Wine)](#62-windows-compatibility-layer-wine)
   - [6.3 Office Font Compatibility Verification](#63-office-font-compatibility-verification)
   - [6.4 Keyboard Shortcut Cheat Sheet](#64-keyboard-shortcut-cheat-sheet)
   - [6.5 Dual-Boot Hardware Clock Fix (RTC UTC)](#65-dual-boot-hardware-clock-fix-rtc-utc)
   - [6.6 Feature: Brisk Time-Travel Instant System Rollback & Checkpoints](#66-feature-brisk-time-travel-instant-system-rollback--checkpoints)
   - [6.7 Feature: Brisk Battery Sentinel Laptop Power Optimization & Profiles](#67-feature-brisk-battery-sentinel-laptop-power-optimization--profiles)
   - [6.8 Feature: Brisk Glide Mode Smart Low-Battery Auto-Pilot](#68-feature-brisk-glide-mode-smart-low-battery-auto-pilot)
   - [6.9 Feature: Brisk Store Modern Curated Application Center](#69-feature-brisk-store-modern-curated-application-center)
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

BriskOS 1.0 LTS is provided as a dual-purpose hybrid live ISO image:
- **Method 1: Live In-Memory Session**: Boot directly into the full Labwc desktop environment without writing a single byte to storage. Ideal for hardware auditing, internet browsing, file recovery, and testing.
- **Method 2: Permanent Installation via Calamares GUI Installer**: Deploy BriskOS permanently to internal NVMe, SSD, or HDD storage using the built-in graphical installer.

---

### 5.1 Launching the Calamares Installer

In the live session, launch the installer through any of the following convenient access points:

1. **Waybar Bottom Taskbar**: Click the dedicated `💿 Install` quick-action button in the left taskbar island.
2. **Desktop Shortcut**: Double-click the **Install BriskOS 1.0 LTS** shortcut icon on the desktop.
3. **Labwc Context Menu**: Right-click anywhere on the desktop wallpaper and select **Install BriskOS 1.0 LTS** from the top of the menu (or navigate to *System -> Install BriskOS*).
4. **Wofi Start Menu**: Press `Super` (Windows key) or click the `❖` start button, type `Install`, and press Enter.
5. **Terminal CLI**: Open Foot terminal (`Super + Enter`) and execute:
   ```bash
   brisk-installer
   ```

> [!NOTE]
> The `brisk-installer` wrapper script verifies live session environment status, configures Qt Wayland compatibility (`QT_QPA_PLATFORM="wayland;xcb"`), acquires polkit permissions passwordlessly via `/etc/polkit-1/rules.d/49-nopasswd_calamares.rules`, and streams real-time debug telemetry to `/var/log/calamares-installer.log`.

---

### 5.2 Method 2: Permanent Installation via Calamares GUI Installer

The Calamares installation wizard provides a streamlined, step-by-step graphical workflow tailored with BriskOS "Night Glass" styling (#0b1120 Midnight Slate background, #38bdf8 Ice Cyan highlights).

```text
+---------------------------------------------------------------------------------+
|  BriskOS 1.0 LTS Installer (Calamares)                                    [X]   |
+-------------------+-------------------------------------------------------------+
|  1. Welcome       |  Welcome to BriskOS 1.0 LTS (Feather)                       |
|  2. Location      |                                                             |
|  3. Keyboard      |  [✓] At least 1.0 GB RAM available                          |
|  4. Partitions    |  [✓] At least 10.0 GB storage available                     |
|  5. Users         |  [✓] Connected to power source                              |
|  6. Summary       |  [✓] Connected to internet (Optional)                       |
|  7. Install       |                                                             |
|  8. Finish        |  Language: [ English (United States)                ▼ ]     |
+-------------------+-------------------------------------------------------------+
|                                                      [ Back ] [ Next ] [ Cancel]|
+---------------------------------------------------------------------------------+
```

#### Step 1: Welcome & Pre-Flight Validation
* **Language Selection**: Select your desired installation and system language from the dropdown menu.
* **Pre-Flight System Requirements Audit**: The installer automatically queries hardware specifications:
  * **Memory**: Minimum 1.0 GB RAM required (2.0+ GB recommended).
  * **Storage**: Minimum 10.0 GB free disk space required (20.0+ GB recommended).
  * **Power Supply**: Connected to external AC power or battery above critical levels.
  * **Internet Connectivity**: Confirms network reachability (optional, offline installation is 100% supported).
* Click **Next** to proceed once hardware checks pass.

#### Step 2: Regional Localization (Locale & Timezone)
* **Timezone Map**: Click on your geographical location on the interactive world map or select your Region and Zone from the dropdown lists (e.g., *America / New_York*, *Europe / London*, *Asia / Tokyo*).
* **System Locale**: Formats dates, numbers, currency, and paper standards to match your regional preferences.
* Click **Next**.

#### Step 3: Keyboard Model & Keymap Selection
* **Keyboard Model**: Select standard generic PC (105-key) or your specific laptop layout.
* **Keymap**: Choose your preferred keyboard language variant (e.g., *English (US)*, *German*, *French AZERTY*, *Spanish*).
* **Interactive Test Input Box**: Type in the test box to confirm special characters, symbols, and alt-key combinations work properly before applying.
* Click **Next**.

#### Step 4: Disk Partitioning (Erase Disk vs Manual Partitioning)
Calamares offers two primary storage strategies:

##### Option 4A: Erase Disk (Automated Clean Installation)
* Ideal for dedicating the entire drive to BriskOS.
* **Select Storage Device**: Choose the target disk drive from the dropdown selector (e.g. `/dev/nvme0n1` or `/dev/sda`).
* **Partition Scheme**: The installer automatically creates an optimal GPT partition layout with an EFI System Partition (512 MB, FAT32 mounted at `/boot/efi`) and a primary root partition formatted in `ext4` mounted at `/`.
* **Swap Options**: Select **No Swap** (recommended, as BriskOS automatically deploys high-speed in-RAM `zram-tools` compressed swap) or **Swap to file**.
* **Encrypt System** *(Optional)*: Check **Encrypt system** and specify a passphrase if LUKS full-disk encryption is required.

##### Option 4B: Manual Partitioning (Dual-Boot & Custom Partition Tables)
* Recommended for dual-booting alongside Windows or preserving existing home partitions.
* Displays current disk partitions, partition flags, filesystems, and unallocated free space.
* **For UEFI Systems**:
  1. Highlight the existing **EFI System Partition** (FAT32, typically 100 MB - 512 MB). Click **Edit**, set Mount Point to `/boot/efi`, keep existing filesystem intact, and ensure **Format** is **unchecked**.
  2. Select the unallocated **Free Space** (minimum 15 GB, recommended 25+ GB). Click **Create**:
     - *Size*: Remaining free space
     - *File system*: `ext4`
     - *Mount point*: `/`
     - *Flags*: `root`
* **For Legacy BIOS (MBR) Systems**:
  1. Select unallocated space and create an `ext4` partition mounted at `/` with the `boot` flag active.
* Click **Next**.

#### Step 5: User Account & Authentication Setup
* **Real Name & Username**: Enter your name (e.g., `Brisk User`) and preferred login username (e.g., `brisk`).
* **Computer Name (Hostname)**: Specify the network hostname for this machine (defaults to `briskos`).
* **User Password**: Enter a strong password for user authentication.
* **Administrative Privileges**:
  * Check **"Log in automatically without asking for the password"** if desired for personal machines.
  * Check **"Use the same password for the administrator (root) account"** (recommended for standard desktop sudo workflow).
* Click **Next**.

#### Step 6: Installation Summary Review
* A comprehensive summary page reviews all impending actions:
  * Target installation disk and partition table modifications.
  * Formatted partitions and mount point bindings.
  * Selected timezone, language, and keyboard layouts.
  * User account configuration.
* > [!WARNING]
  > No changes are written to disk until this step is confirmed. Clicking **Install** begins partition formatting and data extraction. Ensure any critical data on target partitions is backed up.
* Click **Install**, then click **Install Now** on the confirmation dialog.

#### Step 7: Automated Installation & Unsquashfs Extraction
* Calamares initiates the execution phase:
  1. **Partitioning & Formatting**: Creates partition tables and formats filesystems.
  2. **Filesystem Unpacking (`unpackfs`)**: Extracts `/run/live/medium/live/filesystem.squashfs` directly to the target root filesystem.
  3. **Machine ID & FSTAB Generation**: Sets unique `/etc/machine-id` and mounts drives by UUID in `/etc/fstab`.
  4. **Localization & Users**: Generates requested locales, timezone symlinks, and user accounts.
  5. **Network Configuration**: Copies live network configurations to the target system.

#### Step 8: Bootloader Deployment & Live Package Removal
* **GRUB Bootloader Installation**: Calamares runs `grub-install` to register BriskOS in the UEFI boot firmware (`/boot/efi/EFI/briskos/grubx64.efi`) and executes `os-prober` to detect existing OS installations (such as Windows Boot Manager).
* **Automated Live Cleanup (`packages`)**: Automatically uninstalls live session tools and installers from the target disk:
  * Removes: `calamares`, `calamares-settings-debian`, `live-tools`, `live-boot`, `live-config`, `live-config-systemd`.
  * Preserves full offline standalone integrity for the installed system.
* Unmounts all target partitions safely.

#### Step 9: Reboot into BriskOS
* The **Finished** screen confirms successful installation: *"BriskOS 1.0 LTS (Feather) has been installed on your computer."*
* Check the **Restart now** checkbox and click **Done**.
* When the computer reboots, remove the USB installation drive.
* Enjoy your permanent, blazing-fast installation of BriskOS 1.0 LTS!

---

### 5.3 Strategy A: Clean Drive Installation

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

### 5.4 Strategy B: Dual-Boot alongside Windows

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

### 5.5 Disk Partition Layout Reference

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

### 6.6 Feature: Brisk Time-Travel Instant System Rollback & Checkpoints

BriskOS includes an enterprise-grade, zero-friction system snapshot and rollback engine engineered to make breaking updates and unintended configuration errors completely reversible in seconds.

#### A. Core Engine Capabilities
- **Hybrid Snapshot Engine**:
  - Automatically identifies root filesystem backend (`findmnt -n -o FSTYPE /`).
  - **BTRFS Native Mode**: Instantaneous read-only subvolume copy-on-write snapshots (`btrfs subvolume snapshot -r`).
  - **Rsync Hardlink Mode**: When running on Ext4, XFS, or standard filesystems, utilizes hardlink deduplication (`--link-dest`) against the most recent checkpoint. This ensures subsequent snapshots only consume storage for modified files.
- **Automated APT Zero-Friction Hook**:
  - Drops into `/etc/apt/apt.conf.d/80-brisk-timetravel` with `DPkg::Pre-Invoke`.
  - Automatically generates an immutable checkpoint (`auto-apt-...`) right before any `apt upgrade`, `apt install`, or `apt remove` executes.
  - Automatically checks available disk space (requiring $\ge 500$ MB free storage) and gracefully suppresses snapshot creation during live-build chroots or low disk space.
- **Fail-Safe Pre-Restore Checkpoint**:
  - Restoring a checkpoint never performs a destructive, non-reversible overwrite.
  - Prior to syncing files back into `/`, Brisk Time-Travel creates a `safety-pre-restore-...` checkpoint containing the current running state.
  - Preserves critical system paths during restore: `/proc`, `/sys`, `/dev`, `/run`, `/tmp`, `/lost+found`, and preserves `/etc/fstab` and `/boot/efi` UUIDs to guarantee uncompromised hardware bootability.
- **Snapshot Pruning & Retention**:
  - Automatically retains up to 10 snapshots by default (configurable in `/etc/brisk/timetravel.conf`). Expired automated snapshots are pruned sequentially.

#### B. Graphical Interface (`brisk-timetravel-gui`)
Launch **Brisk Time-Travel Recovery** from:
1. Start Menu: **System -> Brisk Time-Travel**
2. Labwc Context Menu: **Right-Click Desktop -> System -> Brisk Time-Travel**
3. Terminal / Runner: `brisk-timetravel-gui`

**Operations Available in the GUI**:
- **⚡ Create Instant Checkpoint**: Prompts for a descriptive comment (e.g., *"Before testing custom NVIDIA drivers"*), displays a pulsating progress dialog, and captures the system state.
- **⏪ Restore to Previous Checkpoint**: Displays an interactive radio list of all captured checkpoints with dates, backend types, disk sizes, and descriptions. Prompts with a confirmation dialogue, creates a safety checkpoint, restores system state, and offers an optional system reboot.
- **📜 View History & Storage Usage**: Generates a detailed audit of existing checkpoints, backend type, disk space utilization, and offers 1-click snapshot deletion.
- **⚙️ Automatic APT Backup Settings**: Toggle automated pre-update APT snapshots on or off.

#### C. Command-Line Interface (`brisk-timetravel`)
The CLI engine can be invoked directly by users in the `sudo` group without password prompts:

```bash
# 1. Create a manual checkpoint with a descriptive comment
brisk-timetravel create "Clean setup before installing custom packages"

# 2. List all available checkpoints and storage telemetry
brisk-timetravel list

# 3. Restore system to a specific checkpoint ID
sudo brisk-timetravel restore 2026-11-12_06-30-00

# 4. Delete an old snapshot
sudo brisk-timetravel delete 2026-11-12_06-30-00

# 5. Output raw pipe-delimited data (for scripting/custom GUIs)
brisk-timetravel list --raw
```

#### D. Configuration File (`/etc/brisk/timetravel.conf`)
```bash
# Enable or disable automated snapshots prior to APT operations
AUTO_BACKUP_ENABLED=true

# Number of snapshots to retain before rotating oldest
MAX_SNAPSHOTS=10

# Base backup storage directory
BACKUP_DIR="/var/backups/brisk-timetravel/snapshots"

# Backend selection: auto | btrfs | rsync
SNAPSHOT_TYPE="auto"
```

---

### 6.7 Feature: Brisk Battery Sentinel Laptop Power Optimization & Profiles

Brisk Battery Sentinel is an ultra-lean power management and battery longevity engine designed to maximize unplugged battery runtime while tripling the physical lifespan of modern laptop lithium-ion battery cells.

#### A. Power Optimization Architecture
- **Drop-In TLP Configuration (`/etc/tlp.d/00-brisk-sentinel.conf`)**:
  - Modern CPU frequency scaling governor profiles for Intel, AMD, and hybrid systems.
  - Dynamic Energy Performance Preference (EPP):
    - **AC Mode**: `CPU_SCALING_GOVERNOR_ON_AC="performance"`, `CPU_ENERGY_PERF_POLICY_ON_AC="performance"`, Turbo Boost enabled.
    - **Battery Mode**: `CPU_SCALING_GOVERNOR_ON_BAT="powersave"`, `CPU_ENERGY_PERF_POLICY_ON_BAT="balance_power"`, PCIe ASPM `powersupersave`, Wi-Fi 802.11 power saving active, and audio chip timeout enabled (1s).
- **1-Click Dynamic Profile Switching**:
  - **🍃 ECO SAVER**: Capped CPU clock ceiling (70%), disabled turbo boost, maximum powersave governor, PCIe powersupersave, and extended background polling intervals (+60% battery life).
  - **⚖️ BALANCED**: Smart on-demand adaptive scaling (schedutil / dynamic powersave) balancing fluid 60 FPS desktop fluidity with thermal efficiency.
  - **⚡ TURBO PERFORMANCE**: 100% uncapped CPU clock ceiling, active Turbo Boost, and maximum PCIe throughput for compilation, gaming, and heavy computing workloads.
- **Hardware Battery Lifespan Protector (Charge Ceiling)**:
  - Continuously keeping lithium-ion batteries charged to 100% at high ambient temperatures accelerates cell chemical degradation.
  - Brisk Battery Sentinel provides a 1-click toggle to enforce an **80% charge ceiling** (`STOP_CHARGE_THRESH_BAT0=80`, `START_CHARGE_THRESH_BAT0=75`).
  - Supports modern Linux 5.14+ sysfs interfaces (`charge_control_end_threshold`), Lenovo IdeaPad conservation mode (`conservation_mode`), ASUS/ThinkPad charge thresholds, and standard TLP hardware controls.

#### B. Graphical Interface (`brisk-sentinel-gui`)
Accessible directly from:
1. **Waybar Battery Module**: Simply left-click the battery icon in the right island.
2. **Start Menu**: **Preferences -> Hardware -> Battery Sentinel**
3. **Labwc Context Menu**: **Right-Click Desktop -> Preferences -> Hardware -> Battery Sentinel**
4. **Terminal / Runner**: `brisk-sentinel-gui`

**Control Panel Features**:
- Real-time battery status header: Capacity (%), Charge state (Charging / Discharging / AC Connected), Battery Health (% of design capacity), Power Draw (instantaneous Watts), Temperature, and Remaining Runtime.
- Active profile indicator & charge protection badge.
- Instant 1-click profile selection: 🍃 ECO SAVER, ⚖️ BALANCED, or ⚡ TURBO PERFORMANCE.
- Battery Lifespan Protector: Toggle 80% Preservation mode or 100% Travel mode.
- Detailed power diagnostics modal displaying hardware vendor, cycle count, voltages, and TLP runtime status.

#### C. Command-Line Interface (`brisk-sentinel`)
The CLI controller executes power adjustments without password prompts for authorized users:

```bash
# 1. Switch power profiles dynamically
brisk-sentinel profile eco
brisk-sentinel profile balanced
brisk-sentinel profile turbo

# 2. View comprehensive battery metrics and telemetry
brisk-sentinel status

# 3. Query machine-readable porcelain status (for custom scripts or Waybar)
brisk-sentinel status --raw

# 4. Configure battery charge ceiling threshold (e.g., 80% stop-charge)
sudo brisk-sentinel threshold 80

# 5. Reset charge ceiling to 100% for long-distance travel
sudo brisk-sentinel threshold 100
```

---

### 6.8 Feature: Brisk Glide Mode Smart Low-Battery Auto-Pilot

**Brisk Glide Mode** is an intelligent, zero-polling battery auto-pilot engine designed to gracefully protect user sessions and extend laptop endurance when battery reserves drop to critical thresholds. Unlike coarse battery-saver utilities, Glide Mode combines kernel-level uevent monitoring with an anti-flicker debounce safety buffer, smooth hardware backlight dimming, and instantaneous charger-restoration recovery.

#### A. Architecture & Event-Driven Engine
- **Zero-Polling Kernel Event Monitoring (`brisk-glide-daemon`)**:
  - Monitors hardware power state via Linux kernel `power_supply` uevents (`udevadm monitor --subsystem-match=power_supply`) with automatic D-Bus fallback (`upower --monitor`).
  - Consumes **0% CPU and zero idle battery draw** while waiting for power transitions.
- **3-Second Anti-Flicker Safety Debounce (`GLIDE_DEBOUNCE_SECONDS`)**:
  - When the AC power cable is disconnected while battery is at or below the trigger threshold, the engine pauses for 3 seconds before engaging Glide Mode.
  - This eliminates jarring brightness and CPU throttling if a power brick is bumped, momentarily loose, or swapped across outlets.
- **Smooth Backlight Dimming (`brightnessctl`)**:
  - Hardware-level, Wayland-native backlight scaling transitions smoothly step-by-step from current brightness down to target level (default 35%).
  - Automatically records pre-dimming brightness level into `/run/brisk/glide-prev-brightness` and restores it smoothly the instant AC mains power is reconnected.
- **Instant Charger Reconnection Recovery**:
  - Plugging in the charger immediately exits Glide Mode without debounce delay: restores the previous active power profile (Balanced or Turbo) and restores original screen brightness.
- **Desktop Session Notification Broadcast**:
  - Emits modern Wayland toasts to active desktop sessions via D-Bus session bus:
    - On engage: `🪫 Baterai Tersisa [X]% — Glide Mode Aktif (Performa hemat daya diaktifkan)`
    - On disengage: `⚡ Charger Terhubung — Glide Mode dinonaktifkan`
- **Waybar Indicator Integration**:
  - Waybar battery island automatically reflects critical Glide status with `🪽🪫 {capacity}%` and detailed tooltip alerting the user that Auto-Guard is engaged.

#### B. Customizable Configuration Settings (`/etc/brisk/glide.conf`)
Glide Mode is governed by `/etc/brisk/glide.conf`, completely customizable via GUI or CLI:

| Parameter | Default | Values | Description |
| :--- | :--- | :--- | :--- |
| `GLIDE_AUTO_ENABLED` | `true` | `true` \| `false` | Enable or disable automatic Glide Mode auto-pilot on low battery. |
| `GLIDE_THRESHOLD` | `20` | `5` - `50` (`20`, `15`, `10`) | Battery capacity percentage threshold that triggers Glide Mode. |
| `GLIDE_AUTO_DIM` | `true` | `true` \| `false` | Smoothly dim screen to `GLIDE_DIM_LEVEL`. If `false`, the screen **remains 100% bright** while CPU and hardware power are aggressively conserved. |
| `GLIDE_DIM_LEVEL` | `35` | `10` - `80` (percentage) | Target screen brightness percentage when dimmed. |
| `GLIDE_DEBOUNCE_SECONDS`| `3` | `0` - `30` (seconds) | Delay buffer to prevent triggering on loose charger cables or accidental unplugs. |
| `GLIDE_NOTIFY` | `true` | `true` \| `false` | Send desktop toast notifications on Glide Mode transitions. |

#### C. Graphical Interface (`brisk-sentinel-gui`)
Open the Battery Sentinel GUI from Waybar battery icon or Start Menu:
1. Select **🪽 Pengaturan Cerdas Glide Mode (Auto-Guard)**.
2. In the Glide settings dialog, you can:
   - **Toggle Auto-Guard**: `[✓] Aktifkan Glide Mode otomatis saat baterai menipis`
   - **Adjust Threshold**: Choose between **20%**, **15%**, or **10%** trigger threshold.
   - **Toggle Screen Auto-Dimming**: `[✓] Redupkan layar secara halus saat Glide Mode aktif`. When unchecked, the screen **stays bright** for presentations, reading, or video playback while CPU/GPU hardware profiles are throttled into Eco Saver mode.
   - **Toggle Debounce**: Enable or disable the 3-second anti-flicker protection buffer.
   - **⚡ Uji Coba Glide Mode Sekarang**: Runs an interactive 5-second simulated Glide Mode cycle to test brightness fading, profile switching, and notification toasts with a live progress dialog.

#### D. Command-Line Interface (`brisk-sentinel glide`)
Manage Glide Mode parameters directly from the terminal:

```bash
# 1. View Glide Mode status and current configuration
brisk-sentinel glide status

# 2. Output raw key-value pairs (for scripting or status bars)
brisk-sentinel glide status --raw

# 3. Enable or disable automatic Glide Mode auto-pilot
sudo brisk-sentinel glide on
sudo brisk-sentinel glide off

# 4. Toggle screen auto-dimming (keep screen bright vs smooth dimming)
sudo brisk-sentinel glide toggle-dim

# 5. Set battery trigger threshold (e.g. 15% or 10%)
sudo brisk-sentinel glide threshold 15

# 6. Set anti-flicker debounce duration (e.g. 3 seconds)
sudo brisk-sentinel glide debounce 3

# 7. Run an interactive 5-second test simulation
brisk-sentinel glide test
```

#### E. Service Management (`brisk-glide.service`)
The background daemon is managed as a standard systemd service unit:

```bash
# Check service status
systemctl status brisk-glide.service

# Restart daemon after manual edits to /etc/brisk/glide.conf
sudo systemctl restart brisk-glide.service
```

---

### 6.9 Feature: Brisk Store Modern Curated Application Center

**Brisk Store** (`brisk-store`) is a featherweight, native graphical application center engineered exclusively for BriskOS 1.0 LTS. Designed adhering strictly to the **Night Glass** design language and `/antislop-ui` standards, Brisk Store delivers an ultra-smooth, 1-click software installation and removal experience without the heavy memory overhead or bloatware typical of traditional Linux package centers (e.g. GNOME Software or Discover).

#### A. Architecture & Dual-Engine Ecosystem
Brisk Store bridges the stability of Debian's native repository with the modernity and sandboxing of Flathub through a seamless dual-engine architecture:
- **Flathub Integration (`flatpak`)**:
  - Automatically configured during live installation via `06-setup-store.hook.chroot` (`https://dl.flathub.org/repo/flathub.flatpakrepo`).
  - Delivers up-to-date proprietary and open-source applications (Google Chrome, Spotify, Visual Studio Code, Discord, Obsidian, Steam) running safely in isolated application sandboxes.
- **Native APT Engine (`apt-get`)**:
  - Leverages Debian 12 (Bookworm) stable repositories for core desktop utilities, system tools, and lightweight editors (GIMP, LibreOffice, Timeshift, GParted, VLC).
- **Decoupled Backend Engine (`/usr/local/bin/brisk-store-backend`)**:
  - High-performance, headless CLI backend handling package inspection, installation, removal, and database updates.
  - Sudo elevation configured through `/etc/sudoers.d/brisk-store` (`NOPASSWD` execution for users in group `%sudo` and live session accounts), enabling zero-prompt installations from the graphical user interface.
  - Automatically triggers `update-desktop-database` and MIME refresh upon completion to ensure immediate desktop availability in menus and file managers.

#### B. Ultra-Lean Memory Guarantee (< 25 MB RAM)
Unlike Electron-based or heavy multi-megabyte app stores:
- **Pure GTK3 / PyGObject Implementation**:
  - Consumes **sub-25 MB RSS RAM** during active browsing, searching, and installation.
  - Sub-300ms application startup time with instantaneous responsive layout rendering.
- **Zero Idle Background Overhead**:
  - Brisk Store operates purely on demand. There are no background telemetry agents, persistent daemons, or notification pollers consuming battery or memory cycles.
  - Upon closing the window, memory footprint instantly returns to **0 MB**.

#### C. Curated Catalog (`/etc/brisk/store/catalog.json`)
The application catalog features over 60 verified, pre-screened desktop packages structured into intuitive categories:
- **⭐ Unggulan (Featured)**: Flagship daily essentials (Google Chrome, Visual Studio Code, Spotify, Telegram, Discord, ONLYOFFICE, VLC, Steam, GIMP, Obsidian).
- **🌐 Internet**: Browsers, communication, and messaging (Chrome, Brave, Firefox ESR, Edge, Telegram, Discord, Thunderbird, Zoom).
- **💻 Coding & Development**: Modern IDEs, editors, and developer toolchains (VS Code, Sublime Text, GitKraken, DBeaver CE, Postman, Node.js, Python IDE, Docker CLI).
- **📝 Office & Productivity**: Document editing, note-taking, and reader apps (ONLYOFFICE Desktop Editors, LibreOffice, Obsidian, Notion, Evince PDF, Typora, Foliate).
- **🎨 Media & Graphics**: Creation and multimedia suites (VLC Media Player, Spotify, GIMP, Inkscape, OBS Studio, Kdenlive, Audacity, Blender).
- **🎮 Gaming**: Game distribution, compatibility layers, and emulators (Steam, Heroic Games Launcher, Lutris, RetroArch, Minetest, Prism Launcher).
- **⚙️ Utilitas**: System maintenance and disk utilities (GParted, Timeshift, BleachBit, FileZilla, qBittorrent, PeaZip).

#### D. Graphical User Interface & Navigation
- **Night Glass Aesthetics**: Deep Midnight Slate canvas (`#0b1120`), translucent card panels (`#0f172a`), refined borders (`#1e293b`), and vibrant Ice Cyan (`#38bdf8`) interactive accents.
- **Integrated Search HeaderBar**: Instant real-time filtering across application names, summaries, and category tags as you type (`🔍 Cari aplikasi di Brisk Store...`).
- **Category & Status Sidebar**: Switch effortlessly between categories or view currently installed software via the *Semua* / *Terpasang* status filter.
- **1-Click Action Flow**:
  - **`+ Pasang`**: Initiates installation via Flathub or APT with animated spinner and live status feedback.
  - **`🗑️ Copot`**: Cleanly uninstalls the application and refreshes desktop launchers with confirmation safety.

#### E. Command-Line Backend Subcommands (`brisk-store-backend`)
Power users and automated deployment scripts can interact directly with the Brisk Store engine:

```bash
# 1. Check application installation status by ID
brisk-store-backend status com.spotify.Client

# 2. Install an application with real-time status output
sudo brisk-store-backend install com.spotify.Client

# 3. Remove/uninstall an application
sudo brisk-store-backend remove com.spotify.Client

# 4. Search curated catalog and remote repositories
brisk-store-backend search "browser"

# 5. List all installed application IDs managed by Brisk Store
brisk-store-backend list-installed
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

# BriskOS 1.0 LTS (Feather)

> **Featherweight, Modern Wayland Linux Distribution**  
> Based on **Debian 12 (Bookworm) amd64** | Sub-512 MB Idle RAM Baseline | Native Wine Integration

---

## Overview

**BriskOS** is an ultra-lightweight, modern desktop Linux distribution engineered for maximum responsiveness, minimal memory footprint, and out-of-the-box Windows application compatibility. Built using Debian's upstream `live-build` framework, BriskOS combines a lightweight stacking Wayland environment with system-level optimizations (zstd zram, PipeWire audio, and streamlined service management).

* **Phase 1**: Foundational infrastructure, Debian Bookworm package manifests, system identity branding, live-build chroot hooks, and the ISO build automation harness.
* **Phase 2**: Complete Desktop Shell & UI Architecture featuring the Labwc Wayland compositor, Waybar bottom taskbar, Wofi Start Menu launcher, Foot terminal, Mako notifications, GTK theming, and aerodynamic vector artwork—strictly governed by antislop-ui design principles.
* **Phase 3**: Seamless Windows Application Compatibility Layer (1-click runner, prefix management control panel), Microsoft Office metric-compatible font substitutions & subpixel rendering optimizations, and Serverless GitHub OTA Update Infrastructure (background daemon, Zenity GUI updater).
* **Phase 4**: Production ISO Build Engine & GitHub Actions CI/CD Pipeline featuring containerized Debian Bookworm Docker build harness (`Dockerfile`, `scripts/build-docker.sh`), hardened host build automation (`scripts/build-iso.sh`) with colorized telemetry, log rotation, pre-flight audit dry-run, and automated cloud release pipeline (`.github/workflows/build-iso.yml`) with cryptographic verification (SHA256 & SHA512).

---

## Architecture & Directory Layout

```text
d:/.Vibe Coder/OS/
├── .github/
│   └── workflows/
│       └── build-iso.yml                    # Production GitHub Actions CI/CD workflow
├── .gitignore                               # Git ignore rules (build trees, caches, ISOs, checksums)
├── auto/
│   └── config                               # live-build automation configuration
├── config/
│   ├── hooks/
│   │   └── live/
│   │       ├── 01-setup-services.hook.chroot # System & PipeWire/WirePlumber user services
│   │       ├── 02-setup-zram.hook.chroot     # zram-tools configuration (zstd, 50% RAM)
│   │       └── 03-setup-wine-mime.hook.chroot # Wine desktop entry & Windows MIME associations
│   ├── includes.chroot/
│   │   ├── etc/
│   │   │   ├── fonts/
│   │   │   │   └── conf.d/
│   │   │   │       ├── 10-brisk-rendering.conf          # Subpixel hinting & LCD filter configuration
│   │   │   │       └── 30-brisk-ms-font-substitutions.conf # 1:1 MS Office metric-compatible font aliases
│   │   │   ├── hostname                     # Hostname configuration ('briskos')
│   │   │   ├── hosts                        # Localhost and loopback definitions
│   │   │   ├── issue                        # TTY pre-login ASCII banner
│   │   │   ├── issue.net                    # Remote login banner
│   │   │   ├── motd                         # Post-login welcome & system diagnostics
│   │   │   ├── os-release                   # freedesktop.org OS identity specification
│   │   │   ├── skel/
│   │   │   │   └── .config/
│   │   │   │       ├── fontconfig/
│   │   │   │       │   └── fonts.conf       # User default font aliases (sans-serif, serif, mono)
│   │   │   │       ├── foot/
│   │   │   │       │   └── foot.ini         # Foot terminal configuration (Slate & Ice Cyan)
│   │   │   │       ├── gtk-3.0/
│   │   │   │       │   └── settings.ini     # GTK 3 theme, Papirus icons, Inter typography
│   │   │   │       ├── gtk-4.0/
│   │   │   │       │   └── settings.ini     # GTK 4 theme, Papirus icons, Inter typography
│   │   │   │       ├── labwc/
│   │   │   │       │   ├── autostart        # Desktop session daemon startup script
│   │   │   │       │   ├── environment      # Wayland session environment variables
│   │   │   │       │   ├── menu.xml         # Desktop right-click openbox-style XML menu
│   │   │   │       │   ├── rc.xml           # Labwc keybinds, mousebinds, window rules
│   │   │   │       │   └── themerc-override # Compositor window borders & menu accents
│   │   │   │       ├── mako/
│   │   │   │       │   └── config           # Notification daemon geometry & colors
│   │   │   │       ├── waybar/
│   │   │   │       │   ├── config.jsonc     # Bottom taskbar modules & quick launchers
│   │   │   │       │   └── style.css        # Antislop-UI taskbar stylesheet
│   │   │   │       └── wofi/
│   │   │   │           ├── config           # Floating Start Menu launcher configuration
│   │   │   │           └── style.css        # Antislop-UI Start Menu stylesheet
│   │   │   └── xdg/
│   │   │       └── autostart/
│   │   │           └── brisk-update-checker.desktop     # Background OTA update checker autostart
│   │   └── usr/
│   │       ├── local/
│   │       │   └── bin/
│   │       │       ├── brisk-wine-runner    # 1-Click Windows binary & installer runner
│   │       │       ├── brisk-wine-config    # Wine GUI control panel & prefix manager
│   │       │       ├── brisk-update-checker # Serverless GitHub OTA update check daemon
│   │       │       └── brisk-updater-gui    # Zenity graphical software updater frontend
│   │       └── share/
│   │           ├── applications/
│   │           │   ├── brisk-wine-runner.desktop        # File manager association for .exe/.msi
│   │           │   ├── brisk-wine-config.desktop        # Wine configuration control panel launcher
│   │           │   └── brisk-updater.desktop            # Start Menu Software Updater launcher
│   │           └── backgrounds/
│   │               └── briskos/
│   │                   └── brisk-default.svg # Bespoke aerodynamic vector wallpaper (1080p)
│   └── package-lists/
│       ├── 00-core-system.list.chroot       # Kernel, non-free firmware, systemd, PipeWire, bootloaders
│       ├── 01-desktop-wayland.list.chroot   # Labwc compositor, Waybar, Wofi, Foot, Thunar
│       ├── 02-office-productivity.list.chroot # LibreOffice/ONLYOFFICE notes, Microsoft fonts, Evince
│       ├── 03-windows-compat.list.chroot    # Wine, Wine64, Winetricks, Cabextract, Zenity
│       └── 04-utilities.list.chroot         # Fastfetch/Neofetch, htop, btop, curl, git, 7zip, pavucontrol
├── Dockerfile                               # Containerized Debian Bookworm build environment
├── scripts/
│   ├── build-docker.sh                      # Cross-platform Docker build harness (Linux, Windows, WSL2)
│   └── build-iso.sh                         # Hardened native ISO build harness with telemetry & checksums
└── README.md                                # Project documentation & technical specifications
```

---

## Component Specifications

### 1. Package Manifests (`config/package-lists/`)

All packages are strictly validated against **Debian 12 (Bookworm)** repository sections (`main`, `contrib`, `non-free`, `non-free-firmware`):

* **`00-core-system.list.chroot`**:
  * **Kernel**: `linux-image-amd64`
  * **Firmware**: `firmware-linux-free`, `firmware-linux-nonfree`, `firmware-misc-nonfree`, `firmware-realtek`, `firmware-iwlwifi`, `firmware-atheros`, `firmware-sof-signed`
  * **Init & Base**: `systemd`, `systemd-sysv`, `udev`, `dbus`, `sudo`, `locales`, `tzdata`
  * **Audio**: `pipewire`, `pipewire-audio-client-libraries`, `pipewire-pulse`, `wireplumber`
  * **Networking**: `network-manager`, `iwd`
  * **Bootloader**: `grub-efi-amd64-bin`, `grub-pc-bin`, `shim-signed` (UEFI + BIOS + Secure Boot ready)

* **`01-desktop-wayland.list.chroot`**:
  * **Compositor**: `labwc` (lightweight stacking Wayland compositor inspired by Openbox)
  * **Shell & Terminal**: `waybar`, `wofi`, `foot`
  * **File Management**: `thunar`, `thunar-archive-plugin`, `thunar-volman`
  * **Session & Utilities**: `mako-notifier`, `swayidle`, `swaylock`, `wl-clipboard`, `grim`, `slurp`, `xwayland`
  * **Theming & Auth**: `polkit-kde-agent-1`, `papirus-icon-theme`, `fonts-inter`, `fonts-noto-color-emoji`

* **`02-office-productivity.list.chroot`**:
  * **Document Editing**: `libreoffice-writer`, `libreoffice-calc` (upstream ONLYOFFICE repo instructions documented)
  * **Typography Compatibility**: `fonts-crosextra-carlito`, `fonts-crosextra-caladea`, `ttf-mscorefonts-installer` (Calibri/Cambria substitutes + core Windows fonts)
  * **Viewers**: `evince` (PDF viewer), `viewnior` (lightweight image viewer)

* **`03-windows-compat.list.chroot`**:
  * **Windows Compatibility**: `wine`, `wine64`, `winetricks`, `cabextract`, `zenity`

* **`04-utilities.list.chroot`**:
  * **System Diagnostics**: `neofetch`, `htop`, `btop`
  * **Networking & Tools**: `curl`, `wget`, `git`, `nano`, `p7zip-full`, `unrar-free`, `pavucontrol`

---

### 2. System Branding & Identity (`config/includes.chroot/etc/`)

* **`os-release`**: Fully compliant with [freedesktop.org os-release](https://www.freedesktop.org/software/systemd/man/os-release.html) standard (`ID=briskos`, `ID_LIKE=debian`, `VERSION_ID="1.0"`, `PRETTY_NAME="BriskOS 1.0 LTS (Feather)"`).
* **`issue` & `issue.net`**: Aerodynamic, non-slop ASCII banner for local TTY and remote logins.
* **`hostname` & `hosts`**: Standardized to hostname `briskos` with loopback bindings (`127.0.0.1`, `127.0.1.1`, IPv6).
* **`motd`**: Concise, actionable welcome screen displaying system specs, memory target, and core CLI commands (`neofetch`, `btop`, `nmtui`).

---

### 3. Live-Build Hooks & System Tuning (`config/hooks/live/`)

All chroot hooks execute during live image assembly with strict `set -euo pipefail` error handling:

* **`01-setup-services.hook.chroot`**:
  * Enables system services (`NetworkManager.service`, `bluetooth.service`, `systemd-timesyncd.service`).
  * Establishes global user session symlinks in `/etc/systemd/user/` for `pipewire.service`, `pipewire-pulse.service`, and `wireplumber.service`.
* **`02-setup-zram.hook.chroot`**:
  * Configures `/etc/default/zramswap` with `ALGO=zstd` and `PERCENT=50` to compress RAM transparently, keeping idle memory footprint below 512 MB.
  * Enables `zramswap.service`.
* **`03-setup-wine-mime.hook.chroot`**:
  * Generates `/usr/share/applications/wine.desktop` (`Exec=wine start /unix %f`).
  * Configures shared MIME associations in `/etc/xdg/mimeapps.list` for `.exe`, `.msi`, `.dll`, and `.scr` executables to open automatically with Wine upon launch.
  * Updates system desktop and MIME databases.

---

### 4. Desktop Shell & UI Architecture (`config/includes.chroot/etc/skel/.config/`)

Phase 2 establishes a high-performance stacking Wayland environment built on top of `labwc` and wlroots protocols, delivering an elegant desktop workflow with minimal overhead.

#### A. Labwc Compositor Configuration (`.config/labwc/`)
* **`rc.xml`**:
  * **Server-Side Decorations**: Standardized titlebars with 8px corner radiuses and Inter typography across all client applications.
  * **Window Snapping**: Super+Left / Super+Right half-screen edge snapping; Super+Up maximize toggle; Super+Down minimize/iconify.
  * **Keyboard Shortcuts**: Standard Alt+F4 (close), Alt+Tab / Alt+Shift+Tab (window cycle), Alt+Space (client menu), Super+Return (Foot terminal), Super+e (Thunar file manager), Super+d & standalone Super_L onRelease (Wofi Start Menu toggle), Super+Shift+c (reload compositor config), Super+l (lock screen).
  * **Mouse Bindings**: Left titlebar drag to move, double-click to maximize, titlebar scroll to shade/unshade, right-click desktop to spawn root menu, Alt+Left/Right drag anywhere on client to move/resize.
* **`autostart`**: Shell startup script launching `swaybg` (with `/usr/share/backgrounds/briskos/brisk-default.svg`), `waybar`, `mako`, multiarch PolicyKit authentication agent, and `swayidle` (600s auto-lock with `swaylock -f -c 0f172a`).
* **`environment`**: Session environment exporting `XDG_CURRENT_DESKTOP=labwc:wlroots`, `XDG_SESSION_TYPE=wayland`, `QT_QPA_PLATFORM=wayland;xcb`, `GDK_BACKEND=wayland,x11`, `MOZ_ENABLE_WAYLAND=1`, and headless rendering optimizers.
* **`menu.xml`**: Clean Openbox-compatible right-click desktop menu featuring quick app launchers, nested Productivity suite (ONLYOFFICE, LibreOffice Writer/Calc, Evince, Viewnior), System diagnostics (`htop`, `btop`, `pavucontrol`), and session controls.
* **`themerc-override`**: Compositor theme overrides specifying deep slate titlebars (`#0f172a`, `#1e293b`), high-contrast text (`#f8fafc`, `#94a3b8`), and Brisk Ice Cyan active borders (`#38bdf8`).

#### B. Waybar Bottom Taskbar & Wofi Start Menu (`.config/waybar/`, `.config/wofi/`)
* **Taskbar (`waybar/config.jsonc` & `waybar/style.css`)**:
  * Positioned at bottom (height: 40px, layer: top).
  * **Left**: Start Menu trigger (`❖ Brisk`), pinned quick launchers for Web Browser, File Manager, Terminal, and Office Suite.
  * **Center**: Interactive window taskbar (`wlr/taskbar`) with Papirus icons, active window indicators, and click-to-activate/close.
  * **Right**: Audio volume with PulseAudio/PipeWire integration, Network status with IP/SSID tooltips and click-to-open `nmtui`, Battery capacity with multi-stage thresholds, Clock with formatted calendar popover, and Power session exit.
* **Start Menu (`wofi/config` & `wofi/style.css`)**:
  * Compact floating launcher (440x500px) anchored to bottom-left (`xoffset: 12`, `yoffset: -52`).
  * Features clean input search field, Papirus icon integration (size: 28px), and purposeful left-border accent indicators (`#38bdf8`) on focused list entries.

#### C. Foot Terminal, Mako Notifications, GTK Defaults & Wallpaper
* **Foot Terminal (`foot/foot.ini`)**: Hardware-accelerated terminal with `monospace:size=11`, 8px centered padding, beam cursor, and full 16-color palette based on deep slate and Ice Cyan.
* **Mako Notifications (`mako/config`)**: Modern notification popups anchored to bottom-right (margin: 12px, border-radius: 8px, font: Inter 10, background: `#1e293be6`, border: `#38bdf8`, 5s auto-timeout).
* **GTK 3 & 4 Settings (`gtk-3.0/settings.ini` & `gtk-4.0/settings.ini`)**: Out-of-the-box configuration applying `Adwaita-dark`, `Papirus-Dark` icon theme, `Inter 10` interface font, and dark theme preference.
* **BriskOS Wallpaper (`usr/share/backgrounds/briskos/brisk-default.svg`)**: Bespoke 1920x1080 aerodynamic vector illustration featuring supersonic flow facets, subtle coordinate grid telemetry, and Brisk Ice Cyan vector streamlines.

---

### 5. Design System & Antislop-UI Compliance

All interface components strictly implement **antislop-ui** principles:
* **Palette Restraint**: Focused palette anchored on deep slate backgrounds (`#0f172a`, `#1e293b`), crisp neutral typography (`#f8fafc`, `#94a3b8`), and a single purposeful accent—**Brisk Ice Cyan** (`#38bdf8`).
* **Zero Slop Elements**: No generic AI purple-to-cyan or pink-to-blue gradients; no excessive pill-shaped buttons; no gratuitous full-screen glassmorphism or blur.
* **Subtle Elevation**: Depth established with restrained 1px borders (`rgba(255, 255, 255, 0.08)`) and solid surface layers.
* **Accessibility & Contrast**: Exceeds WCAG 2.1 Level AAA requirements (Primary text on `#0f172a` achieves **17.06:1** contrast; Ice Cyan on `#0f172a` achieves **8.33:1**).

---

### 6. Windows Application Compatibility Suite (Phase 3)

BriskOS delivers seamless, out-of-the-box Windows application execution on top of Wine 64-bit and custom orchestration utilities:

* **1-Click Application Runner (`usr/local/bin/brisk-wine-runner`)**:
  * Strips `file://` URIs passed from file managers, validates binary targets, and verifies Wine presence.
  * Checks and auto-initializes the user's 64-bit prefix (`$WINEPREFIX`, defaulting to `~/.wine`) on first launch with `WINEARCH=win64` and `WINEDLLOVERRIDES="mscoree,mshtml="` to suppress intrusive Gecko/Mono installation prompts.
  * Dispatches desktop notifications (`notify-send -i wine "BriskOS Windows Layer" "Launching <app>..."`).
  * Distinguishes target types: invokes `wine msiexec /i "$@"` for Windows Installer packages (`.msi`) and `wine start /unix "$@"` for Windows executables (`.exe`).
  * Integrates Zenity graphical error dialogs for missing files, runtime crashes, and missing dependencies.
  * Bound to `.exe` and `.msi` MIME types via `usr/share/applications/brisk-wine-runner.desktop` and `/etc/xdg/mimeapps.list`.

* **Wine Graphical Control Panel (`usr/local/bin/brisk-wine-config`)**:
  * Zenity-driven centralized management utility providing one-click access to:
    * **Wine Configuration (`winecfg`)**: Manage graphics, audio drivers, DPI, and Windows version emulation.
    * **Winetricks Package Manager (`winetricks --gui`)**: Install DirectX runtimes, Visual C++ redistributables, and core Windows components.
    * **Prefix Reset & Factory Reset**: Safely moves existing `~/.wine` to a timestamped backup directory (`~/.wine.backup.<timestamp>`), terminates active wineserver instances, and reinitializes a pristine 64-bit Windows environment.
    * **Windows Task Manager (`wine taskmgr`)**: Monitor and terminate Windows processes.
    * **Windows Registry Editor (`wine regedit`)**: View and modify Wine registry keys.
    * **Process Killer (`wineserver -k`)**: Immediately terminate hanging Wine sessions.
  * Accessible from the Start Menu via `brisk-wine-config.desktop` and the right-click desktop System submenu in `labwc/menu.xml`.

---

### 7. Microsoft Office Font Fidelity & Subpixel Rendering Engine (Phase 3)

BriskOS addresses Linux-to-Windows office document incompatibility (unexpected pagination, wrapping discrepancies, and broken cell boundaries) through system-level Fontconfig XML configurations:

* **1:1 Metric-Compatible Font Substitutions (`etc/fonts/conf.d/30-brisk-ms-font-substitutions.conf`)**:
  * Employs Fontconfig `<match target="pattern">` assignment and `<alias binding="same">` prefer rules to transparently map proprietary Microsoft Office typefaces to open-source metric clones:
    * **Calibri** $\rightarrow$ **Carlito** (Exact 1:1 metric and character width match)
    * **Cambria** $\rightarrow$ **Caladea** (Exact 1:1 serif metric match)
    * **Arial** $\rightarrow$ **Liberation Sans** / **Arial**
    * **Times New Roman** $\rightarrow$ **Liberation Serif** / **Times New Roman**
    * **Courier New** $\rightarrow$ **Liberation Mono** / **Courier New**
    * **Aptos** $\rightarrow$ **Carlito** / **Inter** (Microsoft 365 default fallback)
    * **Segoe UI** $\rightarrow$ **Inter** (Modern Windows UI fallback)
  * Prevents layout shifts, text overflows, and document reflow when opening Word (`.docx`), Excel (`.xlsx`), and PowerPoint (`.pptx`) documents in LibreOffice or ONLYOFFICE.

* **Subpixel Rendering & LCD Optimizations (`etc/fonts/conf.d/10-brisk-rendering.conf`)**:
  * Enables antialiasing (`antialias: true`) and slight bytecode hinting (`hinting: true`, `hintstyle: hintslight`).
  * Enforces RGB subpixel rendering (`rgba: rgb`) with standard LCD filtering (`lcdfilter: lcddefault`) to render crisp, razor-sharp glyph edges on modern laptop and desktop IPS/LCD panels.

* **User Default Font Hierarchy (`etc/skel/.config/fontconfig/fonts.conf`)**:
  * Configures user-level fallback cascades: `sans-serif` $\rightarrow$ **Inter**, `serif` $\rightarrow$ **Liberation Serif**, and `monospace` $\rightarrow$ **DejaVu Sans Mono**.

---

### 8. Serverless GitHub OTA Update Infrastructure (Phase 3)

BriskOS features a lightweight, serverless Over-The-Air (OTA) update system powered by upstream GitHub Releases API and standard Debian package repositories:

* **Background Update Check Daemon (`usr/local/bin/brisk-update-checker`)**:
  * Non-intrusive POSIX daemon running with strict `set -euo pipefail` error handling.
  * Delayed startup (45-second sleep) prevents I/O and network contention during login.
  * Queries GitHub API (`https://api.github.com/repos/briskos/briskos/releases/latest`) with a 5-second connection timeout, user-agent identification, and HTTP 200 payload validation.
  * Extracts remote release tag and compares against local system version (`VERSION_ID` from `/etc/os-release`) using Debian's native `dpkg --compare-versions` with `sort -V` fallback.
  * Dispatches actionable notifications on new version discovery:
    `notify-send -i system-software-update -u normal "BriskOS Update Available" "Version <ver> is ready. Launch Software Updater to install."`
  * Logs all operations to `/tmp/brisk-update-checker.log` and caches release metadata in `/tmp/brisk-latest-release.json`.
  * Autostarted silently on desktop login via `etc/xdg/autostart/brisk-update-checker.desktop` (also supports manual `--now` one-shot execution).

* **Graphical Software Updater (`usr/local/bin/brisk-updater-gui`)**:
  * Zenity-based user-friendly updater frontend.
  * Displays changelog, highlights, and release notes in an interactive modal.
  * Requests explicit user confirmation (`[Update Now]` or `[Cancel]`).
  * Dual-mode update execution:
    * **Graphical Mode**: Executes `pkexec apt-get update && pkexec apt-get dist-upgrade` with a smooth Zenity progress bar.
    * **Terminal Mode**: Spawns `foot` (`--terminal` / `-t`) for real-time APT package download and unpack logs.
  * Displays a post-installation completion dialog and desktop notification noting that system restart is optional.
  * Accessible from the Start Menu via `brisk-updater.desktop` and right-click desktop menu.

---

### 9. ISO Build Engine & CI/CD Infrastructure (Phase 4)

Phase 4 establishes an industrial-grade, multi-tier build and release architecture for BriskOS:

* **Hardened Native Build Harness (`scripts/build-iso.sh`)**:
  * **Strict POSIX & Error Trapping**: Operates under `set -euo pipefail` with automated `ERR`, `INT`, and `TERM` traps capturing failures, tailing the build log, and safely unmounting any active pseudo-filesystems in `chroot/` (`/dev/pts`, `/dev`, `/proc`, `/sys`).
  * **Chroot Mount Protection**: Features a dedicated `cleanup_mounts` routine using `mountpoint -q` checks and lazy forced unmounting (`umount -lf`) to prevent host filesystem pollution or hung mount locks.
  * **Pre-Flight Sanity Audit**: Verifies root permissions, tool presence (`lb`, `debootstrap`, `xorriso`, `mksquashfs`), free storage capacity ($\ge 8$ GB), package manifest validity, and recursive executable bits (`chmod +x`).
  * **Dry-Run Audit Simulation (`--dry-run` / `-d`)**: Allows developers and CI environments on unprovisioned hosts to completely audit package lists, hooks, scripts, and disk readiness without root and without downloading Debian archives.
  * **Colorized Telemetry & Log Rotation**: Real-time ANSI colored terminal output with automated rotation retaining the newest $N$ logs (`--keep-logs 10`).
  * **Zero-Duplication Artifact Standardization**: Standardizes hybrid ISO filenames and output directory routing via atomic moves or hardlinks with symlink compatibility, avoiding duplicate multi-gigabyte ISO copies on disk.
  * **Host User Ownership Mapping**: Automatically detects `$SUDO_UID` / `$SUDO_GID` or `$HOST_UID` / `$HOST_GID` to ensure generated ISO images, checksum files, and build logs are owned by the invoking user rather than locked to root.
  * **Cryptographic Verification**: Generates `BriskOS-1.0-amd64.iso.sha256` and `BriskOS-1.0-amd64.iso.sha512` automatically upon build completion.

* **Containerized Docker Build System (`Dockerfile` & `scripts/build-docker.sh`)**:
  * **Hermetic Debian Bookworm Base**: Containerized around `debian:bookworm` to eliminate host contamination and host OS distribution incompatibilities.
  * **Cross-Platform Compatibility**: Enables building the BriskOS ISO with a single command on Ubuntu, Fedora, Arch, Alpine, macOS (with Docker Desktop), or Windows 10/11 (with Docker Desktop or WSL2).
  * **Windows Git Bash (MSYS) Safe**: Automatically sets `MSYS_NO_PATHCONV=1` to prevent volume bind-mount path mangling when launching Docker from Windows Git Bash.
  * **Privileged Loopback Execution**: Automatically configures `--privileged` loop device pass-through (`/dev/loop*`), host user UID/GID propagation, and workspace volume mounting (`-v $(pwd):/build`).
  * **Interactive Diagnostic Shell (`--shell` / `-s`)**: Enables dropping directly into the container root shell for live-build troubleshooting and environment inspection.

* **Production GitHub Actions CI/CD Pipeline (`.github/workflows/build-iso.yml`)**:
  * **Automated Triggering**: Runs on pushes to `main`/`master`, semantic version tags (`v*`), pull requests, and manual triggers (`workflow_dispatch`).
  * **Runner Storage Optimization**: Automatically cleans pre-installed runner caches (.NET SDK, Android SDK, CodeQL, Haskell, Boost) to release $25+$ GB of disk space on `ubuntu-latest`.
  * **Comprehensive Pre-Flight Static Check**: Validates syntax of all shell scripts (`auto/config`, live hooks, custom binaries, harness scripts) via `bash -n` prior to initiating the multi-stage build.
  * **Toolchain Installation**: Automatically installs `live-build`, `debootstrap`, `xorriso`, `squashfs-tools`, and dual EFI/BIOS bootloader tools.
  * **Post-Build Ownership Normalization**: Restores workspace ownership to the runner user (`id -u:id -g`) so artifact uploads and post-job checkout hooks run without permission errors.
  * **Cryptographic Step Summary**: Publishes ISO file size, SHA256 checksum, and SHA512 hash directly into the GitHub Actions run summary.
  * **Artifact Persistence**: Stores the generated ISO, checksums, and full build logs with 14-day retention.
  * **Failure Diagnostic Capture**: Automatically uploads build failure logs (`logs/`) on failure so issues can be diagnosed immediately from workflow runs.
  * **Automated Tagged Releases**: Automatically creates GitHub Releases for `v*` tags with release notes, attaching the bootable ISO and verification checksums (supports both manual and tag-based release triggers).

---

## QA & Verification Summary

| Check Category | Verification Item | Status |
| :--- | :--- | :---: |
| **Phase 1 Directory Structure** | `config/package-lists/`, `config/includes.chroot/etc/`, `config/hooks/live/`, `auto/`, `scripts/` | **PASS** |
| **Phase 1 Package Repositories** | Debian 12 (Bookworm) package validity across all `.list.chroot` manifests | **PASS** |
| **Phase 1 Script Strictness** | POSIX / Bash syntax checks (`bash -n`, `sh -n`) with `set -euo pipefail` | **PASS** |
| **Phase 1 Standards** | `os-release` freedesktop.org adherence and MIME associations | **PASS** |
| **Phase 2 Directory Structure** | All 14 shell, compositor, and asset configuration files present in `.config/` and `usr/share/backgrounds/` | **PASS** |
| **Phase 2 XML Syntax** | Valid XML structure in `labwc/rc.xml`, `labwc/menu.xml`, and `brisk-default.svg` | **PASS** |
| **Phase 2 JSONC / CSS Syntax** | Valid JSON schema in `waybar/config.jsonc`; balanced block rules in `waybar/style.css` and `wofi/style.css` | **PASS** |
| **Phase 2 INI Syntax** | Section parsing verified in `foot.ini`, `gtk-3.0/settings.ini`, and `gtk-4.0/settings.ini` | **PASS** |
| **Phase 2 Session Scripts** | Shebang and daemon execution checks verified in `labwc/autostart` and `labwc/environment` | **PASS** |
| **Phase 2 Antislop-UI Compliance** | Zero generic AI gradients, restrained geometry, WCAG AAA text contrast (17.06:1) | **PASS** |
| **Phase 3 Directory Structure** | All 11 Windows compatibility, Fontconfig, and OTA updater files present in `usr/local/bin/`, `usr/share/applications/`, `etc/fonts/conf.d/`, `etc/xdg/autostart/`, `etc/skel/.config/fontconfig/` | **PASS** |
| **Phase 3 Shell Script Syntax** | Strict `bash -n` validation and POSIX compliance across `brisk-wine-runner`, `brisk-wine-config`, `brisk-update-checker`, `brisk-updater-gui`, and Wine chroot hooks | **PASS** |
| **Phase 3 Fontconfig XML** | ElementTree schema validation and DTD compliance across `30-brisk-ms-font-substitutions.conf`, `10-brisk-rendering.conf`, and `fonts.conf` | **PASS** |
| **Phase 3 Desktop Entries** | Freedesktop specification compliance, standard Categories, Exec syntax, and MIME bindings for Wine and OTA launchers | **PASS** |
| **Phase 4 Directory Structure** | `.github/workflows/build-iso.yml`, `Dockerfile`, `scripts/build-docker.sh`, enhanced `scripts/build-iso.sh` | **PASS** |
| **Phase 4 Shell Script Strictness** | Strict `bash -n` static syntax validation across all scripts (`build-iso.sh`, `build-docker.sh`, `auto/config`, hooks, `/usr/local/bin`) | **PASS** |
| **Phase 4 Pre-Flight Audit** | `build-iso.sh --dry-run` successfully audits configs, 5 manifests, 3 hooks, 4 binaries, and storage | **PASS** |
| **Phase 4 Mount Cleanup & Signals** | Reverse unmounting (`cleanup_mounts`) and `ERR`/`INT`/`TERM` signal traps verified | **PASS** |
| **Phase 4 Docker Engine Harness** | Clean Dockerfile specification based on Debian Bookworm with non-interactive flags, `MSYS_NO_PATHCONV=1`, and host UID mapping | **PASS** |
| **Phase 4 CI/CD Workflow Schema** | Valid GitHub Actions workflow with runner storage optimization, comprehensive script syntax audits, failure log capture, and release automation | **PASS** |
| **Repository Line Endings** | 100% pure Unix LF line endings (zero CRLF) verified across all files and scripts | **PASS** |

---

## Getting Started: Building the ISO

### Method A: Containerized Build with Docker (Recommended)

The easiest, cross-platform method to build the ISO without installing live-build on your host:

```bash
# Clone the repository
git clone https://github.com/briskos/briskos.git
cd briskos

# Build the ISO using the containerized harness
./scripts/build-docker.sh

# Rebuild container image before assembly (if Dockerfile modified)
./scripts/build-docker.sh --build-image

# Dry-run audit inside container environment
./scripts/build-docker.sh --dry-run

# Launch interactive debugging shell inside container
./scripts/build-docker.sh --shell
```

---

### Method B: Native Host Build (Debian 12 / Ubuntu 22.04+)

If building directly on a Debian/Ubuntu system:

#### 1. Install Prerequisites
```bash
sudo apt-get update
sudo apt-get install -y \
  live-build \
  debootstrap \
  xorriso \
  squashfs-tools \
  dosfstools \
  mtools \
  isolinux \
  syslinux-common \
  grub-pc-bin \
  grub-efi-amd64-bin \
  binutils
```

#### 2. Run Pre-Flight Validation
```bash
# Audit build configuration and prerequisites without building
sudo ./scripts/build-iso.sh --dry-run
```

#### 3. Run Production Build
```bash
# Standard clean production build
sudo ./scripts/build-iso.sh

# Incremental build (skipping clean step for faster debugging)
sudo ./scripts/build-iso.sh --no-clean

# Custom output destination
sudo ./scripts/build-iso.sh -o /var/iso-output
```

---

### Method C: Automated Cloud Build with GitHub Actions

1. Fork or push the repository to GitHub.
2. Navigate to **Actions** $\rightarrow$ **Build BriskOS ISO** $\rightarrow$ **Run workflow**.
3. Once completed, download `BriskOS-1.0-amd64.iso` and checksums directly from the **Artifacts** section.
4. Pushing a version tag automatically publishes a GitHub Release with the ISO attached:
   ```bash
   git tag -a v1.0 -m "Release BriskOS 1.0 LTS"
   git push origin v1.0
   ```

---

## Verifying Image Integrity

Always verify the integrity of the downloaded or built ISO image before flashing:

```bash
# Verify using SHA-256
sha256sum -c BriskOS-1.0-amd64.iso.sha256

# Verify using SHA-512
sha512sum -c BriskOS-1.0-amd64.iso.sha512
```

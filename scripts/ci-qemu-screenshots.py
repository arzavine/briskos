#!/usr/bin/env python3
"""Boot the built BriskOS ISO in QEMU and capture live UI screenshots.

Uses QEMU HMP over TCP to send boot/desktop keystrokes and capture raw PPM
framebuffers via ``screendump``, converting each frame to PNG.
"""

from __future__ import annotations

import argparse
import hashlib
import os
import shutil
import socket
import subprocess
import sys
import time
from pathlib import Path
from typing import Optional

from PIL import Image


KEYMAP = {
    " ": "spc",
    "-": "minus",
    "_": "shift-minus",
    "=": "equal",
    "+": "shift-equal",
    ".": "dot",
    ",": "comma",
    "/": "slash",
    "?": "shift-slash",
    ";": "semicolon",
    ":": "shift-semicolon",
    "'": "apostrophe",
    '"': "shift-apostrophe",
    "[": "bracket_left",
    "{": "shift-bracket_left",
    "]": "bracket_right",
    "}": "shift-bracket_right",
    "\\": "backslash",
    "|": "shift-backslash",
    "`": "grave_accent",
    "~": "shift-grave_accent",
    "!": "shift-1",
    "@": "shift-2",
    "#": "shift-3",
    "$": "shift-4",
    "%": "shift-5",
    "^": "shift-6",
    "&": "shift-7",
    "*": "shift-8",
    "(": "shift-9",
    ")": "shift-0",
    "<": "shift-comma",
    ">": "shift-dot",
    "\n": "ret",
}


class QemuMonitor:
    """Minimal synchronous client for QEMU's Human Monitor Protocol (HMP)."""

    def __init__(self, host: str, port: int, timeout: float = 10.0) -> None:
        self.sock = socket.create_connection((host, port), timeout=timeout)
        self.sock.settimeout(timeout)
        self._drain_banner()

    def _drain_banner(self) -> None:
        deadline = time.time() + 2.0
        buf = b""
        while time.time() < deadline:
            try:
                chunk = self.sock.recv(4096)
                if not chunk:
                    break
                buf += chunk
                if b"(qemu)" in buf:
                    break
            except socket.timeout:
                break

    def cmd(self, line: str, wait: float = 0.2) -> str:
        """Send one HMP command and wait briefly for the next ``(qemu)`` prompt."""
        self.sock.sendall((line.strip() + "\n").encode("ascii"))
        deadline = time.time() + max(wait, 1.5)
        buf = b""
        while time.time() < deadline:
            try:
                chunk = self.sock.recv(4096)
                if not chunk:
                    break
                buf += chunk
                if b"(qemu)" in buf:
                    break
            except socket.timeout:
                break
        if wait > 0:
            time.sleep(wait)
        return buf.decode("utf-8", errors="replace")

    def sendkey(self, combo: str, delay: float = 0.08) -> None:
        self.cmd(f"sendkey {combo}", wait=delay)

    def send_text(self, text: str, delay: float = 0.045) -> None:
        for ch in text:
            if "a" <= ch <= "z" or "0" <= ch <= "9":
                key = ch
            elif "A" <= ch <= "Z":
                key = f"shift-{ch.lower()}"
            elif ch in KEYMAP:
                key = KEYMAP[ch]
            else:
                raise ValueError(f"Unsupported character in send_text: {ch!r}")
            self.cmd(f"sendkey {key}", wait=delay)

    def screendump(self, ppm_path: Path) -> bool:
        self.cmd(f"screendump {ppm_path}", wait=0.4)
        for _ in range(20):
            if ppm_path.exists() and ppm_path.stat().st_size > 64:
                return True
            time.sleep(0.15)
        return False

    def close(self) -> None:
        try:
            self.sock.close()
        except OSError:
            pass


def analyze_ppm(ppm_path: Path) -> dict[str, object]:
    """Return lightweight resolution, color-diversity, and hash stats for a PPM."""
    with Image.open(ppm_path) as img:
        rgb = img.convert("RGB")
        w, h = rgb.size
        thumb = rgb.resize((160, 90))
        pixels = list(thumb.getdata())
        non_black = sum(1 for r, g, b in pixels if (r + g + b) > 18)
        unique_colors = len(set(pixels))
        digest = hashlib.sha256(rgb.tobytes()).hexdigest()
        return {
            "width": w,
            "height": h,
            "non_black_ratio": non_black / len(pixels),
            "unique_colors": unique_colors,
            "sha256": digest,
        }


def save_png(ppm_path: Path, png_path: Path) -> None:
    with Image.open(ppm_path) as img:
        img.save(png_path, format="PNG", optimize=True)


def find_ovmf_pair() -> tuple[Optional[Path], Optional[Path]]:
    code_candidates = [
        Path("/usr/share/OVMF/OVMF_CODE_4M.fd"),
        Path("/usr/share/OVMF/OVMF_CODE.fd"),
        Path("/usr/share/ovmf/OVMF.fd"),
    ]
    vars_candidates = [
        Path("/usr/share/OVMF/OVMF_VARS_4M.fd"),
        Path("/usr/share/OVMF/OVMF_VARS.fd"),
    ]
    code = next((p for p in code_candidates if p.is_file()), None)
    vars_src = next((p for p in vars_candidates if p.is_file()), None)
    return code, vars_src


def build_qemu_cmd(
    iso_path: Path,
    boot_mode: str,
    mon_port: int,
    out_dir: Path,
    work_dir: Path,
) -> list[str]:
    has_kvm = os.path.exists("/dev/kvm") and os.access("/dev/kvm", os.R_OK | os.W_OK)
    cmd = [
        "qemu-system-x86_64",
        "-name",
        "BriskOS-CI-Screenshot",
        "-machine",
        "q35",
        "-m",
        "3072",
        "-smp",
        "2",
        "-display",
        "none",
        "-serial",
        f"file:{out_dir / 'serial.log'}",
        "-monitor",
        f"tcp:127.0.0.1:{mon_port},server,nowait",
        "-vga",
        "virtio",
        "-netdev",
        "user,id=net0",
        "-device",
        "virtio-net-pci,netdev=net0",
        "-boot",
        "order=d,menu=off",
        "-cdrom",
        str(iso_path),
    ]
    if has_kvm:
        cmd.extend(["-accel", "kvm", "-cpu", "host"])
    else:
        cmd.extend(["-accel", "tcg", "-cpu", "max"])

    if boot_mode == "uefi":
        code, vars_src = find_ovmf_pair()
        if code and vars_src:
            vars_rw = work_dir / "ovmf-vars.fd"
            shutil.copy2(vars_src, vars_rw)
            cmd.extend(
                [
                    "-drive",
                    f"if=pflash,format=raw,readonly=on,file={code}",
                    "-drive",
                    f"if=pflash,format=raw,file={vars_rw}",
                ]
            )
        elif code:
            cmd.extend(["-bios", str(code)])

    disk_path = work_dir / "target-disk.qcow2"
    subprocess.run(
        ["qemu-img", "create", "-f", "qcow2", str(disk_path), "20G"],
        check=True,
        stdout=subprocess.DEVNULL,
    )
    cmd.extend(["-drive", f"file={disk_path},if=virtio,format=qcow2"])
    return cmd


def wait_for_monitor(port: int, timeout: float = 20.0) -> QemuMonitor:
    deadline = time.time() + timeout
    last_err: Optional[Exception] = None
    while time.time() < deadline:
        try:
            return QemuMonitor("127.0.0.1", port)
        except OSError as exc:
            last_err = exc
            time.sleep(0.3)
    raise RuntimeError(f"Timed out waiting for QEMU monitor on port {port}: {last_err}")


def is_desktop_framebuffer(stats: dict[str, object]) -> bool:
    """Detect rendered Wayland desktop for both dark and Morning Breeze light themes."""
    return (
        int(stats["unique_colors"]) >= 200
        and float(stats["non_black_ratio"]) >= 0.45
    )


def wait_for_desktop_or_tty(
    mon: QemuMonitor,
    tmp_ppm: Path,
    boot_sha: str,
    timeout_sec: int,
) -> tuple[str, dict[str, object]]:
    """Wait for graphical desktop or detect parked tty1 auto-login console."""
    start = time.time()
    retried_enter = False
    last_ratio = -1.0
    last_colors = -1
    stable_count = 0

    while (time.time() - start) < timeout_sec:
        time.sleep(4.0)
        if not mon.screendump(tmp_ppm):
            continue
        stats = analyze_ppm(tmp_ppm)
        elapsed = int(time.time() - start)
        print(
            f"[{elapsed:3d}s] fb={stats['width']}x{stats['height']} "
            f"non_black={stats['non_black_ratio']:.2f} "
            f"colors={stats['unique_colors']}",
            flush=True,
        )

        if not retried_enter and elapsed >= 12 and stats["sha256"] == boot_sha:
            print("[INFO] Boot screen unchanged at 12s; sending Enter...", flush=True)
            mon.sendkey("ret")
            retried_enter = True
            continue

        if elapsed >= 16 and is_desktop_framebuffer(stats):
            print("[INFO] Graphical desktop detected; settling 8s...", flush=True)
            time.sleep(8.0)
            mon.screendump(tmp_ppm)
            return "desktop", analyze_ppm(tmp_ppm)

        # Detect stable DRM fbcon console or greeter fallback even with a blinking cursor.
        ratio = float(stats["non_black_ratio"])
        colors = int(stats["unique_colors"])
        if elapsed >= 35 and int(stats["width"]) >= 800 and colors >= 20 and ratio >= 0.01:
            if abs(ratio - last_ratio) <= 0.01 and abs(colors - last_colors) <= 5:
                stable_count += 1
            else:
                stable_count = 0
            last_ratio = ratio
            last_colors = colors

            if stable_count >= 4:
                print("[INFO] Stable console/greeter detected; ready for diag/labwc.", flush=True)
                return "tty", stats

    return "timeout", analyze_ppm(tmp_ppm)


def collect_tty_diagnostics_and_launch_labwc(
    mon: QemuMonitor,
    tmp_ppm: Path,
    out_dir: Path,
) -> tuple[bool, dict[str, object]]:
    """Log greetd/systemd diagnostics over serial and launch labwc from tty1."""
    save_png(tmp_ppm, out_dir / "01a-tty1-boot.png")
    print("[SHOT] 01a-tty1-boot.png", flush=True)

    # Switch to tty1 in case greetd is currently parked on VT 7 (e.g. tuigreet).
    mon.sendkey("ctrl-alt-f1", delay=0.5)
    time.sleep(1.5)
    mon.sendkey("ret", delay=0.3)
    time.sleep(0.5)

    diag_cmds = [
        "id user 2>&1 | sudo tee -a /dev/ttyS0\n",
        "systemctl status greetd display-manager getty@tty1 getty@tty7 --no-pager 2>&1 | sudo tee -a /dev/ttyS0\n",
        "journalctl -u greetd -u live-config -b --no-pager 2>&1 | sudo tee -a /dev/ttyS0\n",
        "ls -la /etc/greetd /run/greetd /etc/systemd/system/greetd.service.d /etc/systemd/system/display-manager.service /etc/systemd/system/graphical.target.wants 2>&1 | sudo tee -a /dev/ttyS0\n",
        "cat /run/greetd/config.toml /tmp/brisk-session-*.log 2>&1 | sudo tee -a /dev/ttyS0\n",
        "pgrep -a 'labwc|waybar|swaybg|greetd' 2>&1 | sudo tee -a /dev/ttyS0\n",
    ]
    for cmd in diag_cmds:
        mon.send_text(cmd, delay=0.03)
        time.sleep(1.5)

    print("[INFO] Launching /usr/local/bin/brisk-session from tty1...", flush=True)
    mon.send_text("/usr/local/bin/brisk-session\n", delay=0.04)

    for step in range(10):
        time.sleep(3.0)
        mon.screendump(tmp_ppm)
        stats = analyze_ppm(tmp_ppm)
        print(
            f"[labwc +{step * 3 + 3:2d}s] fb={stats['width']}x{stats['height']} "
            f"non_black={stats['non_black_ratio']:.2f} "
            f"colors={stats['unique_colors']}",
            flush=True,
        )
        if is_desktop_framebuffer(stats):
            time.sleep(6.0)
            mon.screendump(tmp_ppm)
            return True, analyze_ppm(tmp_ppm)

    return False, analyze_ppm(tmp_ppm)


def log_runtime_diagnostics(mon: QemuMonitor) -> None:
    """Dump greetd, user, compositor, waybar, and local session logs to serial.log."""
    cmd = (
        "{ id user; pgrep -a labwc; pgrep -a waybar; "
        "journalctl -u greetd -b --no-pager -n 40; "
        "ls -la ~/.local /tmp/waybar.log; cat /tmp/waybar.log /tmp/brisk-session-*.log; "
        "} 2>&1 | sudo tee -a /dev/ttyS0 >/dev/null\n"
    )
    mon.send_text(cmd, delay=0.025)
    time.sleep(2.0)


def main() -> int:
    parser = argparse.ArgumentParser(description="Capture live BriskOS screenshots in QEMU")
    parser.add_argument("--iso", required=True, help="Path to BriskOS-1.0-amd64.iso")
    parser.add_argument("--out", default="screenshots", help="Output PNG directory")
    parser.add_argument("--boot-mode", choices=["uefi", "bios"], default="uefi")
    parser.add_argument("--boot-timeout", type=int, default=180)
    args = parser.parse_args()

    iso_path = Path(args.iso).resolve()
    out_dir = Path(args.out).resolve()
    work_dir = out_dir / "_work"
    out_dir.mkdir(parents=True, exist_ok=True)
    work_dir.mkdir(parents=True, exist_ok=True)

    if not iso_path.is_file():
        print(f"ERROR: ISO not found: {iso_path}", file=sys.stderr)
        return 1

    mon_port = 4444
    qemu_cmd = build_qemu_cmd(iso_path, args.boot_mode, mon_port, out_dir, work_dir)
    print(f"[INFO] Launching QEMU ({args.boot_mode}): {' '.join(qemu_cmd)}", flush=True)

    qemu_log = (out_dir / "qemu.log").open("w", encoding="utf-8")
    proc = subprocess.Popen(qemu_cmd, stdout=qemu_log, stderr=subprocess.STDOUT)
    tmp_ppm = work_dir / "frame.ppm"
    mon: Optional[QemuMonitor] = None

    try:
        mon = wait_for_monitor(mon_port)

        # 1. Bootloader menu (GRUB / ISOLINUX)
        time.sleep(4.5)
        mon.screendump(tmp_ppm)
        boot_stats = analyze_ppm(tmp_ppm)
        save_png(tmp_ppm, out_dir / "00-boot-menu.png")
        print(f"[SHOT] 00-boot-menu.png ({boot_stats['width']}x{boot_stats['height']})", flush=True)

        mon.sendkey("ret")

        # 2. Wait for Labwc desktop or tty1 fallback
        state, desktop_stats = wait_for_desktop_or_tty(
            mon, tmp_ppm, str(boot_stats["sha256"]), args.boot_timeout
        )

        autologin_ok = state == "desktop"
        if state == "tty":
            desktop_ready, desktop_stats = collect_tty_diagnostics_and_launch_labwc(
                mon, tmp_ppm, out_dir
            )
        else:
            desktop_ready = autologin_ok

        save_png(tmp_ppm, out_dir / "01-desktop.png")
        print(
            f"[SHOT] 01-desktop.png state={state} ready={desktop_ready} "
            f"({desktop_stats['width']}x{desktop_stats['height']}, "
            f"colors={desktop_stats['unique_colors']})",
            flush=True,
        )
        if not desktop_ready:
            print("[WARN] Graphical desktop did not reach threshold.", flush=True)
            return 2

        # 3. Start Menu (Wofi via Super_L, Super+d, or Alt+F1)
        menu_opened = False
        for trigger_key in ("meta_l", "meta_l-d", "alt-f1"):
            mon.sendkey(trigger_key, delay=0.15)
            time.sleep(3.0)
            mon.screendump(tmp_ppm)
            menu_stats = analyze_ppm(tmp_ppm)
            if menu_stats["sha256"] != desktop_stats["sha256"]:
                menu_opened = True
                print(f"[INFO] Wofi launcher opened via {trigger_key}", flush=True)
                break
        if not menu_opened:
            print("[WARN] Start menu did not change framebuffer.", flush=True)
        save_png(tmp_ppm, out_dir / "02-start-menu.png")
        print("[SHOT] 02-start-menu.png", flush=True)
        mon.sendkey("esc", delay=0.2)
        time.sleep(1.5)

        # 4. Open Foot terminal, log runtime diagnostics to serial, clear & show brisk-cockpit
        mon.sendkey("meta_l-ret", delay=0.2)
        time.sleep(3.5)
        log_runtime_diagnostics(mon)
        mon.send_text("/usr/bin/clear && brisk-cockpit\n")
        time.sleep(2.5)
        mon.screendump(tmp_ppm)
        save_png(tmp_ppm, out_dir / "03-terminal-fastfetch.png")
        print("[SHOT] 03-terminal-fastfetch.png", flush=True)

        # 5. Launch Brisk Control Center (then close cleanly with Alt+F4 so focus returns to Foot)
        mon.send_text("brisk-control &\n")
        time.sleep(5.5)
        mon.screendump(tmp_ppm)
        save_png(tmp_ppm, out_dir / "04-brisk-control.png")
        print("[SHOT] 04-brisk-control.png", flush=True)
        mon.sendkey("alt-f4", delay=0.2)
        time.sleep(1.5)
        mon.send_text("pkill -f brisk-control || true\n")
        time.sleep(0.8)

        # 6. Launch Brisk Store (then close cleanly with Alt+F4 so focus returns to Foot)
        mon.send_text("brisk-store &\n")
        time.sleep(5.5)
        mon.screendump(tmp_ppm)
        save_png(tmp_ppm, out_dir / "05-brisk-store.png")
        print("[SHOT] 05-brisk-store.png", flush=True)
        mon.sendkey("alt-f4", delay=0.2)
        time.sleep(1.5)
        mon.send_text("pkill -f brisk-store || true\n")
        time.sleep(0.8)

        # 7. Launch Calamares Installer wrapper
        mon.send_text("brisk-installer &\n")
        time.sleep(7.0)
        mon.screendump(tmp_ppm)
        save_png(tmp_ppm, out_dir / "06-installer.png")
        print("[SHOT] 06-installer.png", flush=True)

        if not autologin_ok:
            print("[WARN] Desktop only started manually via tty1; greetd autologin needs fixing.", flush=True)
            return 3
        return 0
    finally:
        if mon is not None:
            try:
                mon.cmd("quit", wait=0.5)
            except OSError:
                pass
            mon.close()
        try:
            proc.wait(timeout=8)
        except subprocess.TimeoutExpired:
            proc.kill()
        qemu_log.close()
        shutil.rmtree(work_dir, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())

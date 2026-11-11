# BriskOS Design Direction: "Night Glass"

Status: proposal, not implemented. This file is data for the design phase. Nothing here has been applied to `config/` yet.

## 1. Why upgrade

The current shell (Phase 2) is correct but flat. Read against the real files, not the mockups:

- `waybar/style.css`: every module (volume, network, battery, clock, power) is its own bordered box with the same `#1e293b` fill and 6px radius. Seven boxes in a row read as a toolbar, not a taskbar.
- `foot/foot.ini`: `font=monospace` resolves to whatever the system picks (DejaVu Sans Mono). No prompt styling, no icon glyphs, 0.96 alpha with no purpose.
- `labwc/themerc-override`: flat titlebars, square corners, no shadow. A 1px cyan border on the active window is the only depth cue.

Result: consistent, but nothing creates hierarchy or a sense of material.

## 2. Directions considered

| # | Direction | Fit | Verdict |
| :-- | :-- | :-- | :-- |
| A | Flat Slate (current) | Clean, legible, no identity beyond the accent | Baseline |
| B | **Night Glass**: floating grouped bar, translucent surfaces, one glow | Premium, keeps Windows-style layout | **Chosen** |
| C | macOS-style centered dock with magnification | Premium, but breaks the Windows-migrant promise and needs an extra dock app | Rejected |
| D | Neon / cyberpunk glow on every edge | Eye-catching, but the exact "glow everywhere" slop pattern | Rejected |
| E | Material You pastel, large radii | Friendly, but pill shapes everywhere and no link to the slate identity | Rejected |
| F | Terminal-first monochrome, mono font in the shell | Distinct, but alienates the non-programmer audience | Rejected |

## 3. Chosen direction

**Identity:** a quiet, dark glass shell. Depth comes from layering, not decoration. One accent (Ice Cyan `#38bdf8`) marks the single thing that matters at any moment: what is focused.

**Why dark:** the audience codes and works long sessions on laptops, and the slate identity already exists. A light variant is a later toggle (section 9), not a launch requirement.

### Dials

Uses the antislop three-dial scale (1 calm, 2 balanced, 3 bold).

| Dial | Value | Note |
| :-- | :-- | :-- |
| ENERGY | 2 | Three surface layers, one accent, one glow; shadows only on floating things |
| RHYTHM | 2 | Consistent radii and spacing, with deliberate breaks: islands group modules instead of 7 identical boxes |
| MOTION | 2 | 150ms transitions on hover and focus only; no looping or decorative animation |

Density is compact (laptop screens, 40px bar).

### Palette (extends the current tokens, no new hue)

| Token | Value | Use |
| :-- | :-- | :-- |
| `base` | `#0b1120` | Wallpaper floor, behind everything |
| `surface-1` | `#0f172a` | Windows, terminal |
| `surface-2` | `#1e293b` | Raised controls, hover |
| `glass` | `rgba(15,23,42,0.88)` | Bar islands, start menu only |
| `glass-edge` | `rgba(255,255,255,0.10)` | 1px border on glass |
| `glass-highlight` | `rgba(255,255,255,0.06)` | Inset top line, the "lit edge" |
| `text` | `#f8fafc` | Primary |
| `text-muted` | `#94a3b8` | Secondary |
| `accent` | `#38bdf8` | Focus and active only |
| `accent-glow` | `rgba(56,189,248,0.45)` | The one glow (below) |
| `danger` | `#f43f5e` | Errors, power |

### Antislop budget (purpose written down per R-10 / R-13)

- **Glass: 2 elements only.** The bar islands and the start menu. Purpose: these are the only surfaces that float above content, so they are the only ones that need to read as a separate layer. Windows stay solid.
- **Glow: 1 element.** The active-window indicator under the focused task. Purpose: answers "which window has focus" at a glance. No glow on buttons, tray, or borders.
- **Radius:** 14px for floating islands, 10px for windows and menus, 6px for small controls. Never the same value on everything.
- **Shadow:** only on floating elements (islands, menus, windows). Flat elements get none.

### Contrast rule for glass

Glass sits over unknown content, so text contrast must hold in the worst case. Estimated worst case (white window behind, `glass` at 0.88 alpha): effective background about `#2c3344`.

- `#f8fafc` on it: about 11:1.
- `#94a3b8` on it: about 4.9:1, passes AA for 13px text.
- At alpha 0.80 the muted text drops to about 3.7:1 and fails. So **glass alpha must stay at or above 0.88**, and the exclusive zone must keep windows from sliding under the bar.

These are hand estimates. Re-check final values with the antislop contrast tool before shipping.

## 4. Component specs

### 4.1 Taskbar (Waybar), floating islands

- `window#waybar` background fully transparent; the bar is detached with a 8px margin from bottom and sides.
- Three islands, each one continuous glass pill-rectangle (14px radius), not one box per module:
  - **Left:** start button + pinned apps.
  - **Center:** window tasks.
  - **Right:** volume, network, battery, clock, power, separated by 1px dividers inside one island instead of separate boxes.
- Island surface: `glass`, 1px `glass-edge`, `inset 0 1px 0 glass-highlight`, shadow `0 8px 24px rgba(0,0,0,0.35)`.
- Start button: icon-only BriskOS mark, no filled box at rest; `surface-2` on hover, `accent` fill on press.
- Tasks: icon + title, no boxes at rest. Active task gets a 3px rounded `accent` bar underneath with `accent-glow` (`box-shadow: 0 0 12px`). Inactive running tasks get a 3px muted dot.
- Power is the only red element, and only on hover.
- Motion: 150ms ease on background/color; the active bar slides between tasks only if Waybar's version allows (otherwise it simply fades).

### 4.2 Terminal (Foot)

- Font: JetBrains Mono at 11 with explicit bold/italic faces, plus a symbols fallback for prompt icons.
- Palette: keep the 16-color table, retune the ANSI set for harmony on `#0b1120` and re-test every pair for contrast. `regular5` (purple) gets desaturated toward the slate/cyan family.
- Alpha: 0.94 with `surface-1` background. Foot has no blur, so a low alpha would only look muddy; stay high.
- Cursor: beam in `accent`, no blink under 1s intervals.
- Prompt (Starship, if available on the base): two lines, directory and git branch on line one, a single `❯` on line two colored by last exit status. No emoji, no rainbow segments.
- CLI quality-of-life shipped by default: `bat`, `fzf`, `zoxide`, `eza`.
- Terminal chrome: the titlebar comes from Labwc, so it inherits section 4.3.

### 4.3 Windows (Labwc)

- 10px rounded corners and a soft shadow on the active window, a lighter one on inactive.
- Titlebar `surface-2` active / `surface-1` inactive, no gradient. Buttons are small circles that reveal their icon on hover.
- 1px `accent` border on the active window stays; it is the focus signal, consistent with the taskbar glow.
- Snap overlay keeps the `#38bdf833` fill.

### 4.4 Start menu (Wofi)

- Same `glass` treatment as the bar islands, 14px radius, anchored above the start button with a 8px gap.
- Search field is a recessed `surface-1` strip; the selected row gets a 3px `accent` left bar rather than a full cyan fill.
- Result rows: 28px icon, name, muted category label.

### 4.5 Notifications (Mako) and wallpaper

- Mako adopts the same glass fill and 14px radius; urgency shown by the left edge color only.
- Wallpaper: redraw `brisk-default.svg` as a dark `base` field with one soft cyan light source low on one side, so the glass has something to sit on. It must be a single light source, not a grid or orbs.

## 5. Technical constraints (read before promising anything)

1. **No real background blur.** Waybar (GTK) has no `backdrop-filter`, and Labwc has no blur. "Glass" here means translucency plus a lit edge, over a dark wallpaper. True frosted blur needs a different compositor (for example Wayfire's blur plugin, or Hyprland/swayfx off Bookworm). That is a larger decision, see section 8.
2. **Debian 12 package versions are old.** Labwc, Waybar and Wofi on Bookworm may lack features this doc assumes: Labwc corner radius and window shadows, `themerc-override` support, and some Waybar taskbar options. **Verify before writing any CSS** (Phase 0). The existing `themerc-override` file may not even be read by the Bookworm Labwc.
3. **GTK CSS limits.** Waybar supports `rgba`, gradients, `box-shadow` (including `inset`) and `transition`. It does not support `backdrop-filter` or `filter`.
4. **Starship, Nerd Font symbols and some CLI tools may not be in Bookworm.** Check each; the fallback is a documented download step in a build hook, with license review.

## 6. Roadmap

| Phase | Work | Done when |
| :-- | :-- | :-- |
| 0 | Capability audit: install the exact Bookworm versions in a container or VM, list which properties (radius, shadow, `themerc-override`, taskbar options) actually work | A checked table of supported/unsupported items replaces section 5 guesses |
| 1 | Tokens: one shared color/radius/shadow file referenced by Waybar, Wofi, Mako, Foot and Labwc configs | Changing `accent` in one place re-themes everything |
| 2 | Waybar islands, start button, task indicator, divider layout | Real render matches 4.1 |
| 3 | Foot font, palette retune, prompt, CLI defaults | Every ANSI pair passes contrast; prompt verified over real git repos |
| 4 | Labwc window radius/shadow/buttons, Wofi glass, Mako glass | Same glass dose rules hold (2 glass, 1 glow) |
| 5 | Wallpaper redraw, motion pass, optional light variant | Wallpaper supports the glass at all four screen corners |
| 6 | Validation: boot the built ISO in QEMU, take **real** screenshots, run the antislop AFTER audit and the contrast checker | Audit findings fixed; screenshots replace the old mockups |

## 7. Status and known gaps in the existing showcase

The four screenshots in `docs/previews/` were rendered from hand-written HTML/CSS mockups, not from a running BriskOS session. Treat them as concept art. In the showcase document, these are illustrative, not measured: the 178 MiB idle RAM, the boot time under 3.8s, the OS comparison table, the 11.4 MiB Waybar figure, and the Wi-Fi/battery/clock values. The ISO has also never been built end to end (see `README.md` and the Phase 4 notes). Real numbers come from Phase 6 and a real build.

## 8. Decisions needed from the owner

1. **Glass level:** accept "translucent plus lit edge" on the current Labwc stack (cheap, safe), or switch compositor for true blur (better look, more work, more risk).
2. **Base distribution:** stay on Debian 12 and accept old shell versions, or move to a newer Debian base once stable, which makes sections 4.1 to 4.4 much easier.
3. **Light theme:** launch dark-only, or ship a light variant.
4. **Wallpaper direction:** the single-light-source field described in 4.5, or something else.

## 9. Out of scope for this pass

Icon theme replacement, sound design, boot splash and login screen. Each deserves its own short design note after Phase 6.

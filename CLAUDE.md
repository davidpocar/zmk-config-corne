# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

ZMK firmware configuration for a 42-key Corne split keyboard running on `nice_nano` controllers with `nice_view` displays. There is no application code — the whole repo is a keymap plus build/flash tooling. Firmware is compiled in CI, not locally.

## Build & flash workflow

- **Build:** Pushing or opening a PR triggers `.github/workflows/build.yml`, which calls ZMK's reusable `build-user-config.yml`. The build matrix is defined in `build.yaml` (note: `.yaml`, separate from the workflow `.yml`). The result is a downloadable `firmware.zip` artifact containing left + right `.uf2` files.
- **Flash:** `./flash.sh firmware.zip` extracts the zip and flashes both halves sequentially. It waits for the `NICENANO` bootloader volume (double-tap reset on each half when prompted), mounts it, copies the matching `*left*`/`*right*` UF2, and waits for disconnect before moving to the other half.
- There is no local compile step or test suite. Validation is: does CI build succeed, then flash and test on hardware.

## Architecture

The keymap (`config/corne.keymap`) is **not** plain ZMK devicetree — it uses the [urob/zmk-helpers](https://github.com/urob) macro library, pulled in via `config/west.yml` and `#include "zmk-helpers/helper.h"`. This changes how everything is declared:

- `ZMK_LAYER(name, bindings)` — define a layer (replaces the verbose `keymap { layer { bindings = <...> } }` devicetree blocks).
- `ZMK_HOLD_TAP(name, ...)` — define hold-tap behaviors (`hml`/`hmr` are the home-row mods).
- `ZMK_MACRO(name, ...)` and `ZMK_COMBO(name, binding, key-positions, layers)` — macros and combos.
- Key-position constants (`KEYS_L`, `KEYS_R`, `THUMBS`, and per-key labels like `LM3`, `RB1`) come from `#include "zmk-helpers/key-labels/42.h"` — the 42-key positional label set. Use these labels, not raw key indices, when specifying `hold-trigger-key-positions` or combo positions.

### Layers

Layers are referenced by the `#define`d indices at the top of the keymap: `DEF`(0), `LOW`(1), `RAI`(2), `MISC`(3), `NIRI`(4). The base layer is **Colemak-DH**. `NIRI` is a dedicated layer for the Niri window manager (workspace/window navigation via `LG(...)` and `LG(LC(...))` chords).

### Home-row mods

`hml` (left) and `hmr` (right) are positional hold-taps: each restricts `hold-trigger-key-positions` to the *opposite* hand plus thumbs (`KEYS_R THUMBS` / `KEYS_L THUMBS`) so same-hand rolls don't trigger mods. Timing params (`tapping-term-ms`, `quick-tap-ms`, `require-prior-idle-ms`, `flavor`, `hold-trigger-on-release`) are tuned together — when adjusting feel, change them as a set on both `hml` and `hmr` to keep the hands symmetric.

## Conventions

- Editing the keymap and pushing is the entire dev loop — keep changes building. A malformed binding fails CI rather than producing a runtime error.
- `config/corne.conf` holds Kconfig flags (RGB underglow, OLED display) — currently all commented out.
- `.idea/` is committed (PhpStorm project metadata); ignore it for keymap work.

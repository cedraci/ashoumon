class_name Palette
## Canonical GBA-style color palette (original Emerald-inspired art direction —
## warm forest/sandstone/sky tones, not reused Nintendo assets).
## Keep in sync with game/tools/gen_ui_assets.js, which uses the same values to
## generate the pixel-art PNGs this palette is meant to match.

const FOREST_DARK := Color8(46, 92, 58)
const FOREST := Color8(74, 133, 82)
const FOREST_LIGHT := Color8(140, 191, 130)
const SAND := Color8(219, 193, 133)
const SAND_DARK := Color8(176, 140, 92)
const SKY := Color8(140, 190, 214)
const SKY_DARK := Color8(94, 145, 176)
const WATER := Color8(79, 138, 176)
const OUTLINE := Color8(56, 40, 32)
const SHADOW := Color8(150, 112, 78)
const HIGHLIGHT := Color8(255, 250, 235)
const FILL_CREAM := Color8(247, 236, 210)
const TEXT_DARK := Color8(56, 48, 40)
const ACCENT_GOLD := Color8(230, 178, 62)
const ACCENT_RED := Color8(196, 74, 62)

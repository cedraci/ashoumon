// Generates the overworld player sprite and the battle creature placeholder onto
// game/assets/sprites/. Palette values here must match game/scripts/ui/palette.gd,
// plus a couple of character-only tones (skin/hair) not part of that shared palette.
'use strict';

const path = require('path');
const { Canvas } = require('./pixelgen.js');

const OUT_DIR = path.join(__dirname, '..', 'assets', 'sprites');

const PALETTE = {
	OUTLINE: [56, 40, 32, 255],
	FOREST_DARK: [46, 92, 58, 255],
	FOREST: [74, 133, 82, 255],
	SAND: [219, 193, 133, 255],
	SAND_DARK: [176, 140, 92, 255],
	SKIN: [230, 186, 145, 255],
	HAIR: [92, 62, 42, 255],
};

// --- Overworld player: simple original front-facing trainer, 16x16. -----------------
function paintPlayer(x, y) {
	// Cap (rows 1-3): brim + crown, forest-green to match the region's palette.
	if (y === 1 && x >= 5 && x <= 10) return PALETTE.OUTLINE;
	if (y === 2) {
		if (x >= 4 && x <= 11) return x === 4 || x === 11 ? PALETTE.OUTLINE : PALETTE.FOREST_DARK;
	}
	if (y === 3 && x >= 5 && x <= 10) return PALETTE.FOREST;
	// Face (rows 4-6)
	if (y >= 4 && y <= 6) {
		if (x === 5 || x === 10) return PALETTE.OUTLINE;
		if (x >= 6 && x <= 9) return PALETTE.SKIN;
	}
	if (y === 5 && (x === 6 || x === 9)) return PALETTE.OUTLINE; // eyes
	// Body/shirt (rows 7-10)
	if (y >= 7 && y <= 10) {
		if (x === 4 || x === 11) return PALETTE.OUTLINE;
		if (x >= 5 && x <= 10) return PALETTE.SAND;
	}
	if (y === 10 && x >= 5 && x <= 10) return PALETTE.SAND_DARK; // belt line
	// Legs/shoes (rows 11-14)
	if (y >= 11 && y <= 13) {
		if (x === 5 || x === 10) return PALETTE.OUTLINE;
		if ((x >= 6 && x <= 7) || (x >= 8 && x <= 9)) return PALETTE.HAIR;
	}
	if (y === 14 && x >= 5 && x <= 10) return PALETTE.OUTLINE; // shoes
	return null;
}

// --- Battle creatures: shared round-body silhouette, neutral-toned so BattleState's
// per-type modulate tint (fire/water/grass/normal) reads clearly on any of them.
// Each species gets a distinct "topper" (ears/leaf/fin) so they're recognizable even
// before the tint is applied. Generic placeholder = round ears (no species topper).
const BODY = [235, 230, 220, 255]; // near-white so the tint color shows through cleanly
const BODY_SHADE = [205, 199, 188, 255];

function bodyAndFeet(x, y) {
	const cx = 7.5, cy = 9.0, r = 6.2;
	const dx = x - cx, dy = (y - cy) * 1.1;
	const dist = Math.sqrt(dx * dx + dy * dy);
	if (dist <= r) {
		if (dist >= r - 1.1) return PALETTE.OUTLINE;
		if (dx > 1.5 && dy > 0.5) return BODY_SHADE;
		return BODY;
	}
	if (y >= 14 && y <= 15 && (Math.abs(x - 5) <= 1 || Math.abs(x - 10) <= 1)) return PALETTE.OUTLINE;
	return null;
}

function roundEars(x, y) {
	const earL = Math.hypot(x - 3.5, (y - 3) * 1.3) <= 2.2;
	const earR = Math.hypot(x - 11.5, (y - 3) * 1.3) <= 2.2;
	if ((earL || earR) && y <= 5) {
		return Math.hypot(x - (earL ? 3.5 : 11.5), (y - 3) * 1.3) >= 1.3 ? PALETTE.OUTLINE : BODY;
	}
	return null;
}

// Emberkit: pointed fox-like ears.
function pointedEars(x, y) {
	if (y > 5) return null;
	for (const ex of [3, 12]) {
		const spread = 5 - y; // wider base near the body, narrowing to a point upward
		if (y <= 4 && Math.abs(x - ex) <= spread * 0.5) {
			return (Math.abs(x - ex) >= spread * 0.5 - 1 || y === 0) ? PALETTE.OUTLINE : BODY;
		}
	}
	return null;
}

// Leaflet: a broad leaf sprouting from the top of the head, plus a short stem.
function leafTopper(x, y) {
	if (x === 7 && (y === 3 || y === 4)) return PALETTE.OUTLINE; // stem
	const cx = 7.5, cy = 1.6, rx = 2.6, ry = 2.2;
	const dx = (x - cx) / rx, dy = (y - cy) / ry;
	const dist = dx * dx + dy * dy;
	if (y > 3 || dist > 1.0) return null;
	if (dist > 0.62) return PALETTE.OUTLINE;
	if (Math.abs(x - cx) <= 0.5) return PALETTE.FOREST_DARK; // center vein
	return PALETTE.FOREST;
}

// Ripplet: two small triangular fins flaring out from the sides of the head.
const FIN_FILL = [140, 190, 214, 255]; // SKY

function finTopper(x, y) {
	if (y < 5 || y > 8) return null;
	const rowHalfSpan = (3 - Math.abs(y - 6.5) * 2); // widest mid-height, narrows top/bottom
	// Left fin: apex at x=0, base flares toward the head at x=3.
	if (x <= 3 && x <= rowHalfSpan) {
		return x === Math.floor(rowHalfSpan) || x === 0 ? PALETTE.OUTLINE : FIN_FILL;
	}
	// Right fin: mirrored on the other side.
	if (x >= 12 && (15 - x) <= rowHalfSpan) {
		return (15 - x) === Math.floor(rowHalfSpan) || x === 15 ? PALETTE.OUTLINE : FIN_FILL;
	}
	return null;
}

function paintEyes(canvas) {
	canvas.setPixel(6, 9, PALETTE.OUTLINE);
	canvas.setPixel(9, 9, PALETTE.OUTLINE);
}

function makeCreature(topperFn, fileName) {
	const c = new Canvas(16, 16);
	c.forEach((x, y, canvas) => {
		const topper = topperFn(x, y);
		const col = topper || bodyAndFeet(x, y);
		if (col) canvas.setPixel(x, y, col);
	});
	paintEyes(c);
	c.writePNG(path.join(OUT_DIR, fileName));
}

const player = new Canvas(16, 16);
player.forEach((x, y, c) => { const col = paintPlayer(x, y); if (col) c.setPixel(x, y, col); });
player.writePNG(path.join(OUT_DIR, 'player_overworld.png'));

makeCreature(roundEars, 'creature_placeholder.png');
makeCreature(pointedEars, 'emberkit.png');
makeCreature(leafTopper, 'leaflet.png');
makeCreature(finTopper, 'ripplet.png');

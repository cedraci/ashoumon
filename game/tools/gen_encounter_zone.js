// Generates the tall-grass overlay for EncounterZone.tscn onto
// game/assets/tiles/tall_grass_patch.png — a 64x64 patch (matching the zone's
// RectangleShape2D size) so wild-encounter trigger areas read visually as tall
// grass instead of being invisible. Palette values must match palette.gd.
'use strict';

const path = require('path');
const { Canvas } = require('./pixelgen.js');

const OUT_FILE = path.join(__dirname, '..', 'assets', 'tiles', 'tall_grass_patch.png');
const SIZE = 64;
const MOTIF = 8;

const BASE = [46, 92, 58, 255];       // FOREST_DARK — darker than the plain grass tile
const BLADE = [140, 191, 130, 255];   // FOREST_LIGHT
const BLADE_MID = [74, 133, 82, 255]; // FOREST
const OUTLINE = [56, 40, 32, 210];    // slightly translucent base-of-blade shadow

// One 8x8 repeating motif: a couple of tall two-pixel blades per cell.
function paintMotif(x, y) {
	if (x === 1 && y >= 1 && y <= 5) return y <= 2 ? BLADE : BLADE_MID;
	if (x === 4 && y >= 0 && y <= 4) return y <= 1 ? BLADE : BLADE_MID;
	if (x === 6 && y >= 2 && y <= 6) return y <= 3 ? BLADE : BLADE_MID;
	if ((x === 1 || x === 4 || x === 6) && y === 7) return OUTLINE; // base shadow
	return BASE;
}

const canvas = new Canvas(SIZE, SIZE);
canvas.forEach((x, y, c) => {
	c.setPixel(x, y, paintMotif(x % MOTIF, y % MOTIF));
});
canvas.writePNG(OUT_FILE);

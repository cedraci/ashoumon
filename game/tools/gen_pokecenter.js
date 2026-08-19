// Generates the Pokémon Center building backdrop onto
// game/assets/tiles/pokecenter_building.png — a 48x48 decorative sprite (matches
// the 3x3-tile obstacle footprint added to overworld_map.gd's OBSTACLES). Palette
// values must match game/scripts/ui/palette.gd plus ACCENT_RED for the roof.
'use strict';

const path = require('path');
const { Canvas } = require('./pixelgen.js');

const OUT_FILE = path.join(__dirname, '..', 'assets', 'tiles', 'pokecenter_building.png');
const SIZE = 48;

const OUTLINE = [56, 40, 32, 255];
const ROOF = [196, 74, 62, 255];       // ACCENT_RED
const ROOF_DARK = [156, 55, 46, 255];
const WALL = [219, 193, 133, 255];     // SAND
const WALL_DARK = [176, 140, 92, 255]; // SAND_DARK
const DOOR = [92, 62, 42, 255];

function paint(x, y) {
	// Roof: triangular peak, rows 0-19, widening from the apex down to row 19.
	if (y < 20) {
		const roofHalfWidth = (y / 19) * 24;
		const distFromCenter = Math.abs(x - 23.5);
		if (distFromCenter <= roofHalfWidth) {
			return distFromCenter >= roofHalfWidth - 2 ? ROOF_DARK : ROOF;
		}
		return null; // outside the roof triangle, above the walls: transparent
	}
	// Outline around the building's footprint.
	if (x === 0 || x === SIZE - 1 || y === SIZE - 1) return OUTLINE;
	// Walls with a centered door.
	if (y >= 34) {
		if (x >= 20 && x <= 27) {
			return (x === 20 || x === 27 || y === 34) ? OUTLINE : DOOR;
		}
	}
	return (x === 1 || x === SIZE - 2) ? WALL_DARK : WALL;
}

const canvas = new Canvas(SIZE, SIZE);
canvas.forEach((x, y, c) => {
	const col = paint(x, y);
	if (col) c.setPixel(x, y, col);
});
canvas.writePNG(OUT_FILE);

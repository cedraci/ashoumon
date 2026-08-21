// Generates the overworld tile atlas onto game/assets/tiles/atlas.png.
// Layout must match game/scripts/overworld/overworld_map.gd's TILE_SIZE (16) and
// its GRASS_COORDS=(0,0) / WALL_COORDS=(1,0) cells: a 16x16 grid, tiles laid out
// left-to-right. Palette values here must match game/scripts/ui/palette.gd.
'use strict';

const path = require('path');
const { Canvas } = require('./pixelgen.js');

const OUT_FILE = path.join(__dirname, '..', 'assets', 'tiles', 'atlas.png');
const TILE = 16;

const PALETTE = {
	FOREST_DARK: [46, 92, 58, 255],
	FOREST: [74, 133, 82, 255],
	FOREST_LIGHT: [140, 191, 130, 255],
	OUTLINE: [56, 40, 32, 255],
	SHADOW: [150, 112, 78, 255],
	SAND: [219, 193, 133, 255],
	SAND_DARK: [176, 140, 92, 255],
};

function paintTile(canvas, tx, ty, painter) {
	for (let y = 0; y < TILE; y++) {
		for (let x = 0; x < TILE; x++) {
			const color = painter(x, y);
			if (color) canvas.setPixel(tx * TILE + x, ty * TILE + y, color);
		}
	}
}

// Grass: flat base + a handful of hand-placed darker/lighter blade marks so it
// reads as textured ground rather than a flat color swatch, GBA-tile style.
const DARK_BLADES = [[2, 3], [2, 4], [9, 2], [13, 6], [4, 10], [11, 11], [6, 13], [1, 12]];
const LIGHT_BLADES = [[6, 2], [11, 5], [3, 8], [14, 9], [9, 13], [1, 6]];

function paintGrass(x, y) {
	for (const [bx, by] of DARK_BLADES) {
		if ((x === bx && y === by) || (x === bx && y === by + 1)) return PALETTE.FOREST_DARK;
	}
	for (const [bx, by] of LIGHT_BLADES) {
		if ((x === bx && y === by) || (x === bx && y === by + 1)) return PALETTE.FOREST_LIGHT;
	}
	return PALETTE.FOREST;
}

function paintPath(x, y) {
	if ((x + y) % 7 === 0 || (x * 3 + y) % 11 === 0) return PALETTE.SAND_DARK;
	return PALETTE.SAND;
}

function paintFlower(x, y) {
	const grass = paintGrass(x, y);
	if ((x === 7 && y === 5) || (x === 8 && y === 5)) return PALETTE.SAND;
	if ((x === 7 && y === 6) || (x === 8 && y === 6)) return PALETTE.SAND_DARK;
	return grass;
}

// Tree: rounded dark-outlined canopy over a short trunk, on a grass background so
// it blends with neighboring grass cells on the same TileMapLayer (this tile fully
// replaces a cell rather than layering on top of it).
function paintTree(x, y) {
	// Trunk
	if (x >= 6 && x <= 9 && y >= 11 && y <= 15) {
		if (x === 6 || x === 9 || y === 15) return PALETTE.OUTLINE;
		return PALETTE.SHADOW;
	}
	// Canopy: rounded silhouette via distance from an offset center.
	const cx = 7.5, cy = 6.5, r = 6.5;
	const dx = x - cx, dy = (y - cy) * 1.05;
	const dist = Math.sqrt(dx * dx + dy * dy);
	if (dist <= r) {
		if (dist >= r - 1.1) return PALETTE.OUTLINE;
		// Highlight upper-left quadrant, shade lower-right.
		if (dx < -0.5 && dy < -0.5) return PALETTE.FOREST_LIGHT;
		if (dx > 1.0 && dy > 1.0) return PALETTE.FOREST_DARK;
		return PALETTE.FOREST;
	}
	return paintGrass(x, y);
}

const atlas = new Canvas(TILE * 4, TILE);
paintTile(atlas, 0, 0, paintGrass);
paintTile(atlas, 1, 0, paintTree);
paintTile(atlas, 2, 0, paintPath);
paintTile(atlas, 3, 0, paintFlower);
atlas.writePNG(OUT_FILE);

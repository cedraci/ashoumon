'use strict';

const path = require('path');
const { Canvas } = require('./pixelgen.js');

const OUT_FILE = path.join(__dirname, '..', 'assets', 'tiles', 'house_small.png');
const WIDTH = 48;
const HEIGHT = 40;

const OUTLINE = [56, 40, 32, 255];
const ROOF = [72, 112, 142, 255];
const ROOF_LIGHT = [112, 155, 174, 255];
const ROOF_DARK = [48, 76, 105, 255];
const WALL = [232, 216, 170, 255];
const WALL_SHADE = [194, 168, 122, 255];
const WINDOW = [92, 160, 172, 255];
const WINDOW_LIGHT = [174, 224, 220, 255];
const DOOR = [92, 62, 42, 255];
const FLOWER = [202, 91, 119, 255];
const LEAF = [74, 133, 82, 255];

function paint(x, y) {
	// Roof peak with alternating highlight bands for a clean, readable silhouette.
	if (y < 18) {
		const halfWidth = Math.floor((y + 1) * 1.45);
		const distance = Math.abs(x - 23.5);
		if (distance <= halfWidth) {
			if (distance >= halfWidth - 2) return ROOF_DARK;
			if ((x + y) % 7 === 0) return ROOF_LIGHT;
			return ROOF;
		}
		return null;
	}
	// Eaves and wall outline.
	if (y === 18 || x === 2 || x === 45 || y === 39) return OUTLINE;
	if (y >= 19 && y <= 38) {
		if (x >= 7 && x <= 16 && y >= 23 && y <= 30) {
			if (x === 7 || x === 16 || y === 23 || y === 30) return OUTLINE;
			return (x + y) % 4 === 0 ? WINDOW_LIGHT : WINDOW;
		}
		if (x >= 31 && x <= 40 && y >= 23 && y <= 30) {
			if (x === 31 || x === 40 || y === 23 || y === 30) return OUTLINE;
			return (x + y) % 4 === 0 ? WINDOW_LIGHT : WINDOW;
		}
		if (x >= 20 && x <= 27 && y >= 31) {
			if (x === 20 || x === 27 || y === 31) return OUTLINE;
			return DOOR;
		}
		if (x === 3 || x === 44 || y === 38) return WALL_SHADE;
		return WALL;
	}
	// A little flower box below the left window.
	if (y === 32 && x >= 8 && x <= 15) return WALL_SHADE;
	if (y === 33 && (x === 10 || x === 13)) return FLOWER;
	if (y === 34 && (x === 10 || x === 13)) return LEAF;
	return null;
}

const canvas = new Canvas(WIDTH, HEIGHT);
canvas.forEach((x, y, c) => {
	const color = paint(x, y);
	if (color) c.setPixel(x, y, color);
});
canvas.writePNG(OUT_FILE);

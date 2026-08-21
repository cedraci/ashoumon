'use strict';

const path = require('path');
const { Canvas } = require('./pixelgen.js');

const OUT_DIR = path.join(__dirname, '..', 'assets', 'tiles');
const OUTLINE = [56, 40, 32, 255];
const WALL = [232, 216, 170, 255];
const WALL_SHADE = [194, 168, 122, 255];
const ROOF = [143, 89, 112, 255];
const ROOF_LIGHT = [193, 132, 143, 255];
const DOOR = [92, 62, 42, 255];
const WATER = [72, 145, 184, 255];
const WATER_LIGHT = [132, 207, 220, 255];
const STONE = [150, 154, 151, 255];
const STONE_DARK = [92, 101, 102, 255];
const GOLD = [236, 191, 86, 255];

function writeHouse() {
	const canvas = new Canvas(64, 48);
	canvas.forEach((x, y, c) => {
		let color = null;
		if (y < 20) {
			const halfWidth = Math.floor((y + 1) * 1.6);
			const distance = Math.abs(x - 31.5);
			if (distance <= halfWidth) color = distance >= halfWidth - 2 ? ROOF : ((x + y) % 8 === 0 ? ROOF_LIGHT : ROOF);
		} else if (y === 20 || x === 2 || x === 61 || y === 47) {
			color = OUTLINE;
		} else {
			color = WALL;
			if (x === 3 || x === 60 || y === 46) color = WALL_SHADE;
			if (x >= 12 && x <= 23 && y >= 26 && y <= 35) color = (x === 12 || x === 23 || y === 26 || y === 35) ? OUTLINE : WATER_LIGHT;
			if (x >= 40 && x <= 51 && y >= 26 && y <= 35) color = (x === 40 || x === 51 || y === 26 || y === 35) ? OUTLINE : WATER_LIGHT;
			if (x >= 27 && x <= 36 && y >= 36) color = (x === 27 || x === 36 || y === 36) ? OUTLINE : DOOR;
		}
		if (color) c.setPixel(x, y, color);
	});
	canvas.writePNG(path.join(OUT_DIR, 'town_hall.png'));
}

function writeFountain() {
	const canvas = new Canvas(24, 16);
	canvas.forEach((x, y, c) => {
		let color = null;
		if (y >= 9 && y <= 13 && x >= 2 && x <= 21) color = x === 2 || x === 21 || y === 9 ? STONE_DARK : STONE;
		if (y >= 11 && y <= 13 && x >= 4 && x <= 19) color = WATER;
		if (x >= 9 && x <= 14 && y >= 5 && y <= 10) color = y === 5 ? GOLD : STONE;
		if (x >= 10 && x <= 13 && y >= 3 && y <= 5) color = WATER_LIGHT;
		if (x === 8 || x === 15) color = WATER_LIGHT;
		if (color) c.setPixel(x, y, color);
	});
	canvas.writePNG(path.join(OUT_DIR, 'town_fountain.png'));
}

writeHouse();
writeFountain();

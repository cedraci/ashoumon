// Generates the battle backdrop onto game/assets/tiles/battle_bg.png: sky gradient,
// ground band, and two platform ellipses positioned under Battle.tscn's fixed
// EnemySprite (170,45) and PlayerSprite (60,100) positions (both scale 2x, 16x16
// source sprites, so their ground contact points are ~16px below those positions).
'use strict';

const path = require('path');
const { Canvas } = require('./pixelgen.js');

const OUT_FILE = path.join(__dirname, '..', 'assets', 'tiles', 'battle_bg.png');
const W = 240, H = 160;
const HORIZON = 70;

const SKY_DARK = [94, 145, 176];
const SKY = [140, 190, 214];
const GROUND = [46, 92, 58];
const GROUND_NEAR = [74, 133, 82];
const PLATFORM = [219, 193, 133];
const PLATFORM_EDGE = [176, 140, 92];

function lerp(a, b, t) {
	return [
		Math.round(a[0] + (b[0] - a[0]) * t),
		Math.round(a[1] + (b[1] - a[1]) * t),
		Math.round(a[2] + (b[2] - a[2]) * t),
		255,
	];
}

function ellipseAt(x, y, cx, cy, rx, ry) {
	const dx = (x - cx) / rx, dy = (y - cy) / ry;
	return dx * dx + dy * dy;
}

const canvas = new Canvas(W, H);
canvas.forEach((x, y, c) => {
	if (y < HORIZON) {
		c.setPixel(x, y, lerp(SKY_DARK, SKY, y / HORIZON));
	} else {
		c.setPixel(x, y, y < HORIZON + 5 ? GROUND_NEAR : GROUND);
	}
});

const platforms = [
	{ cx: 170, cy: 61, rx: 22, ry: 7 },  // enemy: sprite center (170,45) + ~16px half-height
	{ cx: 60, cy: 116, rx: 27, ry: 9 },  // player: sprite center (60,100) + ~16px half-height
];

for (const p of platforms) {
	for (let y = Math.floor(p.cy - p.ry - 1); y <= p.cy + p.ry + 1; y++) {
		for (let x = Math.floor(p.cx - p.rx - 1); x <= p.cx + p.rx + 1; x++) {
			const d = ellipseAt(x, y, p.cx, p.cy, p.rx, p.ry);
			const dEdge = ellipseAt(x, y, p.cx, p.cy, p.rx + 1, p.ry + 1);
			if (d <= 1.0) canvas.setPixel(x, y, PLATFORM);
			else if (dEdge <= 1.0) canvas.setPixel(x, y, PLATFORM_EDGE);
		}
	}
}

canvas.writePNG(OUT_FILE);

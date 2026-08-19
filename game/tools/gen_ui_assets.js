// Generates this pass's UI chrome PNGs (textbox/menu panel, selection cursor,
// continue indicator) onto game/assets/ui/, using the shared pixelgen.js canvas.
// Palette values here must match game/scripts/ui/palette.gd.
'use strict';

const path = require('path');
const { Canvas } = require('./pixelgen.js');

const OUT_DIR = path.join(__dirname, '..', 'assets', 'ui');

const PALETTE = {
	OUTLINE: [56, 40, 32, 255],
	SHADOW: [150, 112, 78, 255],
	HIGHLIGHT: [255, 250, 235, 255],
	FILL_CREAM: [247, 236, 210, 255],
	ACCENT_GOLD: [230, 178, 62, 255],
};

// --- Panel 9-slice (textbox / menu list background) ---------------------------------
// 12x12 source: 1px dark outline, 1px highlight (top/left) or shadow (bottom/right)
// bevel ring, cream fill center. StyleBoxTexture margins = 3px per side so only the
// flat cream interior stretches, keeping the outline/bevel crisp at any control size.
function makePanel() {
	const W = 12, H = 12;
	const c = new Canvas(W, H);
	c.forEach((x, y, canvas) => {
		const distTop = y;
		const distLeft = x;
		const distBottom = H - 1 - y;
		const distRight = W - 1 - x;
		const d = Math.min(distTop, distLeft, distBottom, distRight);
		if (d === 0) {
			canvas.setPixel(x, y, PALETTE.OUTLINE);
		} else if (d === 1) {
			const nearTopOrLeft = distTop === 1 || distLeft === 1;
			const nearBottomOrRight = distBottom === 1 || distRight === 1;
			if (nearBottomOrRight && !nearTopOrLeft) {
				canvas.setPixel(x, y, PALETTE.SHADOW);
			} else {
				canvas.setPixel(x, y, PALETTE.HIGHLIGHT);
			}
		} else {
			canvas.setPixel(x, y, PALETTE.FILL_CREAM);
		}
	});
	return c;
}

// --- Triangle helper (used for the selection cursor + continue indicator) -----------
function sign(p1, p2, p3) {
	return (p1[0] - p3[0]) * (p2[1] - p3[1]) - (p2[0] - p3[0]) * (p1[1] - p3[1]);
}

function pointInTriangle(pt, v1, v2, v3) {
	const d1 = sign(pt, v1, v2);
	const d2 = sign(pt, v2, v3);
	const d3 = sign(pt, v3, v1);
	const hasNeg = d1 < 0 || d2 < 0 || d3 < 0;
	const hasPos = d1 > 0 || d2 > 0 || d3 > 0;
	return !(hasNeg && hasPos);
}

function expandFromCentroid(verts, scale) {
	const cx = (verts[0][0] + verts[1][0] + verts[2][0]) / 3;
	const cy = (verts[0][1] + verts[1][1] + verts[2][1]) / 3;
	return verts.map(([x, y]) => [cx + (x - cx) * scale, cy + (y - cy) * scale]);
}

function drawTriangle(canvas, verts, color) {
	for (let y = 0; y < canvas.height; y++) {
		for (let x = 0; x < canvas.width; x++) {
			if (pointInTriangle([x + 0.5, y + 0.5], verts[0], verts[1], verts[2])) {
				canvas.setPixel(x, y, color);
			}
		}
	}
}

function makeOutlinedTriangle(verts, fillColor) {
	const c = new Canvas(8, 8);
	drawTriangle(c, expandFromCentroid(verts, 1.4), PALETTE.OUTLINE);
	drawTriangle(c, verts, fillColor);
	return c;
}

// Right-pointing arrow: sits to the left of the selected menu item.
function makeCursorArrow() {
	return makeOutlinedTriangle([[1, 1], [1, 7], [7, 4]], PALETTE.ACCENT_GOLD);
}

// Down-pointing chevron: "more text below" indicator in the textbox.
function makeContinueIndicator() {
	return makeOutlinedTriangle([[1, 1], [7, 1], [4, 7]], PALETTE.ACCENT_GOLD);
}

makePanel().writePNG(path.join(OUT_DIR, 'panel_9slice.png'));
makeCursorArrow().writePNG(path.join(OUT_DIR, 'cursor_arrow.png'));
makeContinueIndicator().writePNG(path.join(OUT_DIR, 'continue_indicator.png'));

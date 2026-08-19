// Dependency-free pixel-art -> PNG generator used to author this project's GBA-style
// UI/tile/sprite assets as code instead of hand-editing raster files. Reused across
// every asset-generation pass (UI chrome, tileset, sprites, battle backdrop).
'use strict';

const fs = require('fs');
const zlib = require('zlib');

const CRC_TABLE = (() => {
	const table = new Uint32Array(256);
	for (let n = 0; n < 256; n++) {
		let c = n;
		for (let k = 0; k < 8; k++) {
			c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
		}
		table[n] = c >>> 0;
	}
	return table;
})();

function crc32(buf) {
	let c = 0xFFFFFFFF;
	for (let i = 0; i < buf.length; i++) {
		c = CRC_TABLE[(c ^ buf[i]) & 0xFF] ^ (c >>> 8);
	}
	return (c ^ 0xFFFFFFFF) >>> 0;
}

function chunk(type, data) {
	const typeBuf = Buffer.from(type, 'ascii');
	const lenBuf = Buffer.alloc(4);
	lenBuf.writeUInt32BE(data.length, 0);
	const crcBuf = Buffer.alloc(4);
	crcBuf.writeUInt32BE(crc32(Buffer.concat([typeBuf, data])), 0);
	return Buffer.concat([lenBuf, typeBuf, data, crcBuf]);
}

class Canvas {
	constructor(width, height) {
		this.width = width;
		this.height = height;
		this.pixels = new Uint8Array(width * height * 4); // RGBA, starts transparent
	}

	inBounds(x, y) {
		return x >= 0 && y >= 0 && x < this.width && y < this.height;
	}

	setPixel(x, y, [r, g, b, a = 255]) {
		if (!this.inBounds(x, y)) return;
		const i = (y * this.width + x) * 4;
		this.pixels[i] = r;
		this.pixels[i + 1] = g;
		this.pixels[i + 2] = b;
		this.pixels[i + 3] = a;
	}

	getPixel(x, y) {
		const i = (y * this.width + x) * 4;
		return [this.pixels[i], this.pixels[i + 1], this.pixels[i + 2], this.pixels[i + 3]];
	}

	fillRect(x0, y0, w, h, color) {
		for (let y = y0; y < y0 + h; y++) {
			for (let x = x0; x < x0 + w; x++) {
				this.setPixel(x, y, color);
			}
		}
	}

	forEach(fn) {
		for (let y = 0; y < this.height; y++) {
			for (let x = 0; x < this.width; x++) {
				fn(x, y, this);
			}
		}
	}

	toPNGBuffer() {
		const raw = Buffer.alloc(this.height * (1 + this.width * 4));
		let offset = 0;
		for (let y = 0; y < this.height; y++) {
			raw[offset++] = 0; // filter type: none
			const rowStart = y * this.width * 4;
			raw.set(this.pixels.subarray(rowStart, rowStart + this.width * 4), offset);
			offset += this.width * 4;
		}
		const idatData = zlib.deflateSync(raw, { level: 9 });

		const ihdr = Buffer.alloc(13);
		ihdr.writeUInt32BE(this.width, 0);
		ihdr.writeUInt32BE(this.height, 4);
		ihdr[8] = 8;  // bit depth
		ihdr[9] = 6;  // color type: RGBA
		ihdr[10] = 0; // compression
		ihdr[11] = 0; // filter
		ihdr[12] = 0; // interlace

		const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
		return Buffer.concat([
			signature,
			chunk('IHDR', ihdr),
			chunk('IDAT', idatData),
			chunk('IEND', Buffer.alloc(0)),
		]);
	}

	writePNG(path) {
		fs.writeFileSync(path, this.toPNGBuffer());
		console.log(`wrote ${path} (${this.width}x${this.height})`);
	}
}

module.exports = { Canvas, crc32 };

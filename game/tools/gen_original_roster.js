'use strict';

const fs = require('fs');
const path = require('path');

const OUT_DIR = path.join(__dirname, '..', 'data', 'species');
const SPRITE = 'res://assets/sprites/creature_placeholder.png';

// Original creature names. They are intentionally independent of existing game IP.
const NAMES = [
	'Brindleaf', 'Mossprig', 'Thornlet', 'Petalume', 'Bramblet', 'Glimmoss', 'Rootle', 'Florafawn', 'Vineloo', 'Bloomble',
	'Emberoo', 'Cindercub', 'Flarefin', 'Ashpup', 'Kindrake', 'Blazeling', 'Searwing', 'Pyrova', 'Coalisk', 'Fumefang',
	'Rillip', 'Drizzlet', 'Brookit', 'Mistling', 'Puddlefin', 'Rainrel', 'Tidelet', 'Foamander', 'Dewlisk', 'Surgebud',
	'Pebblit', 'Craggle', 'Bouldoon', 'Flintail', 'Rubblet', 'Clastora', 'Gravello', 'Stoneling', 'Quarron', 'Obsidillo',
	'Breezlet', 'Whispry', 'Gustling', 'Zephyroo', 'Cloudlet', 'Draftalon', 'Cirrella', 'Soarbit', 'Vortivue', 'Airstag',
	'Shadel', 'Duskit', 'Noctowlit', 'Gloombat', 'Murkwisp', 'Umbrakit', 'Dreadle', 'Veilisk', 'Sombren', 'Nightnib',
	'Sparkit', 'Voltlet', 'Coilcub', 'Zappup', 'Brightail', 'Ampraze', 'Staticorn', 'Surglow', 'Thundrel', 'Luminox',
	'Frostip', 'Chilloo', 'Snowlet', 'Glacibud', 'Rimepaw', 'Icicleaf', 'Frostril', 'Hailisk', 'Cryonix', 'Winteroo',
	'Bloomink', 'Mirebud', 'Sporell', 'Funglow', 'Moldrill', 'Bogbit', 'Mycora', 'Toadstooly', 'Rotroot', 'Puffern',
	'Chirplet', 'Beetlebit', 'Cocoonel', 'Mothree', 'Stinglet', 'Carapax', 'Weavisp', 'Hornibble', 'Silkora', 'Swarmite',
	'Prowlet', 'Fanglet', 'Scruffox', 'Clawkit', 'Razoroo', 'Howlisk', 'Brutalon', 'Snarlit', 'Ravengale', 'Maneon',
	'Flufflet', 'Cuddlit', 'Bunbloom', 'Pawpuff', 'Snuggleaf', 'Dottibee', 'Mallowisp', 'Cozyrn', 'Plumpling', 'Velvetail',
	'Wispcoil', 'Tinklet', 'Glimmeru', 'Chimelet', 'Prismite', 'Shimmeron', 'Orbilume', 'Mirroryx', 'Stellune', 'Aurorling',
	'Gadget', 'Coglet', 'Brassbit', 'Gearling', 'Rivetoon', 'Platilisk', 'Ironbud', 'Chromite', 'Mechamoss', 'Ferron',
	'Driplume', 'Saltusk', 'Shellit', 'Pearlume', 'Corallet', 'Seabloom', 'Trawlon', 'Nautilune', 'Reefang', 'Abyssprig',
	'Sunseed', 'Dawnling', 'Raylet', 'Solaraft', 'Daybloom', 'Heliopup', 'Goldrake', 'Radiantle', 'Solstagon', 'Dayflare',
	'Moonbit'
];

const TYPES = ['grass', 'fire', 'water', 'normal'];
const ROSTER_NAMES = NAMES.slice(0, 151);

function stat(index, offset, spread) {
	return 35 + ((index * 17 + offset) % spread);
}

function makeResource(name, index) {
	const id = name.toLowerCase();
	const type = TYPES[(index - 1) % TYPES.length];
	const hp = stat(index, 3, 31);
	const attack = stat(index, 11, 36);
	const defense = stat(index, 19, 36);
	const specialAttack = stat(index, 7, 36);
	const specialDefense = stat(index, 23, 31);
	const speed = stat(index, 29, 41);
	return `[gd_resource type="Resource" load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://scripts/data/species.gd" id="1_script"]\n\n[resource]\nscript = ExtResource("1_script")\nid = "${id}"\ndex_number = ${index}\ndisplay_name = "${name}"\nbase_hp = ${hp}\nbase_attack = ${attack}\nbase_defense = ${defense}\nbase_special_attack = ${specialAttack}\nbase_special_defense = ${specialDefense}\nbase_speed = ${speed}\ntype_id = "${type}"\ncatch_rate = 45\nsprite_path = "${SPRITE}"\n`;
}

if (ROSTER_NAMES.length !== 151) throw new Error(`Expected 151 names, got ${ROSTER_NAMES.length}`);
fs.mkdirSync(OUT_DIR, { recursive: true });
for (let i = 0; i < ROSTER_NAMES.length; i++) {
	const number = String(i + 1).padStart(3, '0');
	const filePath = path.join(OUT_DIR, `original_${number}.tres`);
	fs.writeFileSync(filePath, makeResource(ROSTER_NAMES[i], i + 1));
}
console.log(`wrote ${ROSTER_NAMES.length} original species resources to ${OUT_DIR}`);

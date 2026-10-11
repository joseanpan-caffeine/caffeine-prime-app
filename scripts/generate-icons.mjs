// Gera PNGs placeholder (fundo escuro + "P" âmbar) sem dependências externas.
// Uso: node scripts/generate-icons.mjs
import { deflateSync } from 'node:zlib';
import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const BG = [0x0e, 0x0b, 0x09];
const AMBER = [0xe0, 0xa2, 0x4a];
const WHITE = [0xff, 0xff, 0xff];

const crcTable = new Uint32Array(256).map((_, n) => {
  let c = n;
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  return c >>> 0;
});
function crc32(buf) {
  let c = 0xffffffff;
  for (const b of buf) c = crcTable[(c ^ b) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}
function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const td = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(td));
  return Buffer.concat([len, td, crc]);
}
function png(size, pixel) {
  const raw = Buffer.alloc((size * 4 + 1) * size);
  for (let y = 0; y < size; y++) {
    raw[y * (size * 4 + 1)] = 0;
    for (let x = 0; x < size; x++) {
      const [r, g, b, a] = pixel(x, y);
      const o = y * (size * 4 + 1) + 1 + x * 4;
      raw[o] = r; raw[o + 1] = g; raw[o + 2] = b; raw[o + 3] = a;
    }
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(size, 0); ihdr.writeUInt32BE(size, 4);
  ihdr[8] = 8; ihdr[9] = 6; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('IDAT', deflateSync(raw)),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}
// "P" desenhada por retângulos num grid 10x10 (bowl + haste)
function isP(nx, ny) {
  const stem = nx >= 0.3 && nx < 0.45 && ny >= 0.22 && ny < 0.8;
  const top = nx >= 0.3 && nx < 0.68 && ny >= 0.22 && ny < 0.34;
  const mid = nx >= 0.3 && nx < 0.68 && ny >= 0.46 && ny < 0.58;
  const side = nx >= 0.56 && nx < 0.7 && ny >= 0.26 && ny < 0.56;
  return stem || top || mid || side;
}
function logo(size, { bg = BG, fg = AMBER, transparent = false, scale = 1 } = {}) {
  return png(size, (x, y) => {
    const nx = (x / size - 0.5) / scale + 0.5;
    const ny = (y / size - 0.5) / scale + 0.5;
    if (isP(nx, ny)) return [...fg, 255];
    return transparent ? [0, 0, 0, 0] : [...bg, 255];
  });
}
mkdirSync(join(root, 'assets'), { recursive: true });
writeFileSync(join(root, 'assets/icon.png'), logo(1024));
writeFileSync(join(root, 'assets/splash-icon.png'), logo(512, { transparent: true }));
writeFileSync(join(root, 'assets/android-icon-foreground.png'), logo(1024, { transparent: true, scale: 0.66 }));
writeFileSync(join(root, 'assets/android-icon-background.png'), png(1024, () => [...BG, 255]));
writeFileSync(join(root, 'assets/android-icon-monochrome.png'), logo(1024, { fg: WHITE, transparent: true, scale: 0.66 }));
writeFileSync(join(root, 'assets/favicon.png'), logo(64));
console.log('Ícones gerados em assets/');

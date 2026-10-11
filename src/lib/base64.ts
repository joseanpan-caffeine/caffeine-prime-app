const CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

/** Base64 para strings ASCII (suficiente para "chave:" do Basic auth). */
export function base64Ascii(input: string): string {
  let out = '';
  for (let i = 0; i < input.length; i += 3) {
    const a = input.charCodeAt(i);
    const b = i + 1 < input.length ? input.charCodeAt(i + 1) : NaN;
    const c = i + 2 < input.length ? input.charCodeAt(i + 2) : NaN;
    const n = (a << 16) | ((Number.isNaN(b) ? 0 : b) << 8) | (Number.isNaN(c) ? 0 : c);
    out += CHARS[(n >> 18) & 63];
    out += CHARS[(n >> 12) & 63];
    out += Number.isNaN(b) ? '=' : CHARS[(n >> 6) & 63];
    out += Number.isNaN(c) ? '=' : CHARS[n & 63];
  }
  return out;
}

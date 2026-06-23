// run_wasm.mjs -- the WASM host (node's engine = the "computer" that runs the .wasm; like the OS PE loader).
// Provides env.putc (the host's byte-output, analogous to x86 calling kernel32 WriteFile).  Collects output
// and writes it raw to fd 1 (byte-identical to the x86 WriteFile path) before propagating main()'s i64 as exit.
import { readFileSync, writeSync } from 'node:fs';
const bytes = readFileSync(process.argv[2]);
const out = [];
const imports = { env: { putc: (c) => out.push(Number(c) & 0xff) } };
const { instance } = await WebAssembly.instantiate(bytes, imports);
const r = instance.exports.main();
if (out.length) writeSync(1, Buffer.from(out));
process.exit(Number(r) & 0xff);

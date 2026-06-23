// run_wasm.mjs -- the WASM host (node's WebAssembly engine = the "computer" that runs the .wasm,
// analogous to the OS PE loader running a PE).  Instantiate, call main(), propagate its i64 as exit code.
import { readFileSync } from 'node:fs';
const bytes = readFileSync(process.argv[2]);
const { instance } = await WebAssembly.instantiate(bytes);
const r = instance.exports.main();
process.exit(Number(r));

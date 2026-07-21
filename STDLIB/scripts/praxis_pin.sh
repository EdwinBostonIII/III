#!/usr/bin/env bash
# praxis_pin.sh -- PostToolUse: the HARNESS authors the pin. The agent may append CLAIMS;
# only this hook appends PINS -- content digests and observed gate output, things no model authors.
#
# Trace is keyed by session_id (hooks are PROJECT-scoped: a shared trace would let one session's
# green gate license another session's claim -- the recorded cross-session disqualifier).
# Fail-open everywhere: a confused pinner pins NOTHING and exits 0; it never blocks, never fakes.
#
# Pins:
#   Edit|Write  -> [edit_<name> < sha_<12>]      (content digest of the file as it now IS)
#   Bash        -> [gate_green < exit_zero]      only when the command names a *_gate.sh AND the
#                  observed output carries the gate's own uppercase GREEN marker (gates print GREEN
#                  only on their green path; RED paths say "not green" in lowercase). The exit code
#                  is not in the payload; the marker is the gate speaking, observed by the harness.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PRAXIS_DIR="$ROOT/.praxis"
node -e '
const fs = require("fs"), path = require("path"), crypto = require("crypto");
let s = "";
process.stdin.on("data", d => s += d).on("end", () => {
  try {
    const j = JSON.parse(s);
    const sid = String(j.session_id || "").replace(/[^A-Za-z0-9-]/g, "");
    if (!sid) return;                                    /* no session identity -> no pin */
    const pins = [];
    const tool = j.tool_name || "";
    if (tool === "Edit" || tool === "Write") {
      const f = (j.tool_input && j.tool_input.file_path) || "";
      if (f && fs.existsSync(f) && fs.statSync(f).isFile()) {
        const h = crypto.createHash("sha256").update(fs.readFileSync(f)).digest("hex").slice(0, 12);
        /* EIDOLOS idents are LOWERCASE: one uppercase scroll poisons the whole trace read
         * (syntax refusal -> lawcheck fails -> the house collapses and every claim is refused).
         * Proven live 07-21: [edit_MEMORY_md < ...] flipped an earned STANDS to a mass DEFECT. */
        const nm = path.basename(f).replace(/[^A-Za-z0-9]/g, "_").toLowerCase();
        if (nm) pins.push("[edit_" + nm + " < sha_" + h + "]");
      }
    } else if (tool === "Bash") {
      const cmd = (j.tool_input && j.tool_input.command) || "";
      const out = JSON.stringify(j.tool_response || {});
      if (/_gate\.sh/.test(cmd) && /GREEN/.test(out) && !/GATE_EXIT=[1-9]/.test(out)) {
        pins.push("[gate_green < exit_zero]");
      }
    }
    if (!pins.length) return;
    fs.mkdirSync(process.env.PRAXIS_DIR, { recursive: true });
    fs.appendFileSync(path.join(process.env.PRAXIS_DIR, sid + ".trace"), pins.join("\n") + "\n");
  } catch (e) { /* fail-open: pin nothing */ }
});
' 2>/dev/null
exit 0

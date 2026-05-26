#!/usr/bin/env bash
# verify_reach_remote.sh -- The Reach, Phase 3 LIVE E2E: prove the L4 remote tier fetches a
# content-addressed blob over REAL HTTP and content-verifies it.  A single-process corpus KAT
# cannot drive client + server (recv deadlock), so the server runs as a SEPARATE python process.
#
# Flow: start a blob server that serves BLOB at /<sha256(BLOB)>; build+run the .iii client
# (STDLIB/corpus/_reach_remote_e2e.iii) which points reach at it and fetches addr=sha256(BLOB);
# the client returns 99 iff the fetched bytes re-hash to the requested address.  NIH note: python
# is the TEST HARNESS only (like the cartographer) -- not part of the III artifact.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"
LIB="$ROOT/STDLIB/build/iii/libiii_native.a"
CLIENT="$ROOT/STDLIB/corpus/_reach_remote_e2e.iii"
PORT=18080
BLOB="REACH-OVER-HTTP-OK"
PY=python; command -v python >/dev/null 2>&1 || PY=python3

ADDR=$("$PY" -c "import hashlib;print(hashlib.sha256(b'$BLOB').hexdigest())")
echo "[reach-e2e] serving blob (sha256=$ADDR) at http://127.0.0.1:$PORT/$ADDR"

"$PY" - "$PORT" "$BLOB" "$ADDR" >/dev/null 2>&1 <<'PY' &
import sys, http.server
port = int(sys.argv[1]); blob = sys.argv[2].encode(); addr = sys.argv[3]
class H(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.0"
    def do_GET(self):
        if self.path == "/" + addr:
            self.send_response(200)
            self.send_header("Content-Length", str(len(blob)))
            self.end_headers()
            self.wfile.write(blob)
        else:
            self.send_response(404); self.end_headers()
    def log_message(self, *a): pass
http.server.HTTPServer(("127.0.0.1", port), H).serve_forever()
PY
SRV=$!
sleep 1

"$IIIS" "$CLIENT" --compile-only --out /tmp/rre.o >/tmp/rre_build.log 2>&1 || { echo "[reach-e2e] compile FAILED"; kill "$SRV" 2>/dev/null; exit 2; }
gcc /tmp/rre.o -Wl,--start-group "$LIB" -Wl,--end-group -lws2_32 -lkernel32 -o /tmp/rre.exe >>/tmp/rre_build.log 2>&1 || { echo "[reach-e2e] link FAILED"; kill "$SRV" 2>/dev/null; exit 2; }

( cd /tmp && timeout 20 ./rre.exe ); RC=$?
kill "$SRV" 2>/dev/null
rm -f /tmp/iii_reach_store.bin

echo "[reach-e2e] client EXIT=$RC (99 = fetched over HTTP + content-verified; 1/2/3 = check; 124 = timeout)"
if [ "$RC" -eq 99 ]; then echo "[reach-e2e] PASS -- the L4 remote tier fetches + content-verifies over real HTTP"; exit 0; else echo "[reach-e2e] FAIL"; exit 1; fi

#!/usr/bin/env bash
# Benchmark sdust-cr (Crystal) vs sdust-or (original C).
# Prints a summary and saves it to results/<TAG>.md so versions can be compared
# later with a plain `diff results/<old>.md results/<new>.md`.
#
# Usage:  ./bench.sh [TAG]                 TAG defaults to `git describe`
#         CHROM=chr1 ./bench.sh v0.1.6     override subset / window via env
set -euo pipefail
cd "$(dirname "$0")"

ROOT="$(cd ../.. && pwd)"
CHROM="${CHROM:-chr21}"; W="${W:-64}"; T="${T:-20}"
FA="../data/$CHROM.fa"; GZ="../data/$CHROM.fa.gz"
CR="../bin/sdust-cr"; OR="../bin/sdust-or"
TAG="${1:-$(cd "$ROOT" && git describe --tags --always 2>/dev/null || echo untagged)}"
OUT="../results/$TAG.md"; mkdir -p ../results
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
say(){ printf '\n== %s ==\n' "$*"; }

# 0. subset (only if missing)
if [ ! -f "$FA" ]; then
  say "prepare $CHROM"
  samtools faidx ../data/JG3.0.0.fa "$CHROM" > "$FA"; samtools faidx "$FA"
  bgzip -k -f "$FA"; samtools faidx "$GZ"
fi

# 1. correctness gate — a speed/memory comparison only means something if the
#    two programs produce identical output.
say "verify identical output"
"$CR" -w "$W" -t "$T" "$FA" 2>/dev/null > "$TMP/cr.txt"
"$OR" -w "$W" -t "$T" "$FA" 2>/dev/null > "$TMP/or.txt"
diff -q "$TMP/cr.txt" "$TMP/or.txt" >/dev/null || { echo "OUTPUT DIFFERS — aborting"; exit 1; }
MD5=$(md5sum "$TMP/cr.txt" | cut -d' ' -f1); LINES=$(wc -l < "$TMP/cr.txt")
echo "ok: $LINES intervals (md5 $MD5)"

# 2. wall clock — .fa and .gz so gzip cost = (cr-gz − cr-fa)
say "wall clock"
hyperfine -w1 -r5 --export-json "$TMP/wall.json" \
  -n cr-fa "$CR -w $W -t $T $FA" -n or-fa "$OR -w $W -t $T $FA" \
  -n cr-gz "$CR -w $W -t $T $GZ" -n or-gz "$OR -w $W -t $T $GZ"

# 3. peak RSS — what the user feels. 2 rounds because GC makes it vary.
say "peak RSS"
for _ in 1 2; do
  python3 maxrss.py "$CR" -w "$W" -t "$T" "$FA" | tee -a "$TMP/mem.txt"
  python3 maxrss.py "$OR" -w "$W" -t "$T" "$FA" | tee -a "$TMP/mem.txt"
done

# 4. allocation attribution — which code allocates the extra memory (GC.stats)
say "allocation (GC.stats)"
(cd "$ROOT" && crystal build --release benchmark/scripts/bench_core.cr -o "$TMP/bench_core") >/dev/null 2>&1
"$TMP/bench_core" "$FA" "$W" "$T" | tee "$TMP/alloc.txt"

# 5. CPU — counters (cr vs or) + the single hottest function
say "perf"
perf stat -- "$CR" -w "$W" -t "$T" "$FA" >/dev/null 2>"$TMP/ps_cr.txt"
perf stat -- "$OR" -w "$W" -t "$T" "$FA" >/dev/null 2>"$TMP/ps_or.txt"
perf record -g -o "$TMP/perf.data" -- "$CR" -w "$W" -t "$T" "$FA" >/dev/null 2>&1
perf report -i "$TMP/perf.data" --stdio --no-children 2>/dev/null \
  | awk '/^[[:space:]]+[0-9].*sdust-cr/ { print; exit }' > "$TMP/top.txt" || true

# --- write the one-page summary ---
TMP="$TMP" TAG="$TAG" CHROM="$CHROM" W="$W" T="$T" MD5="$MD5" LINES="$LINES" \
COMMIT="$(cd "$ROOT" && git rev-parse --short HEAD 2>/dev/null || echo -)" \
CRY="$(crystal --version 2>/dev/null | head -1)" HOST="$(uname -srm)" DATE="$(date -Iseconds)" \
python3 - <<'PY' > "$OUT"
import os, json, re
T=os.environ
tmp=T["TMP"]
def rd(p):
    try: return open(os.path.join(tmp,p)).read()
    except: return ""
wall={r["command"]:r["mean"] for r in json.load(open(f"{tmp}/wall.json"))["results"]}
mem={}
for ln in rd("mem.txt").splitlines():
    mb=float(ln.split()[0]); who="cr" if "sdust-cr" in ln else "or"
    mem[who]=max(mem.get(who,0),mb)
a=rd("alloc.txt")
def m(pat,s=a):
    g=re.search(pat,s); return g.group(1) if g else "-"
norm=m(r"\[normalize\].*allocated=([\d.]+)MB"); core=m(r"\[core\+norm\].*allocated=([\d.]+)MB")
def insn(p):
    g=re.search(r"([\d,]+)\s+instructions", rd(p)); return g.group(1) if g else "-"
top=rd("top.txt").strip()
top=re.sub(r"\s+"," ",top).split("] ",1)[-1] if top else "-"
def rt(x,y):
    try: return f"{x/y:.2f}x"
    except: return "-"
print(f"""# sdust benchmark — {T['TAG']}

- commit `{T['COMMIT']}` · {T['CRY']} · {T['HOST']}
- data: {T['CHROM']} (w={T['W']} t={T['T']}) · {T['LINES']} intervals · md5 `{T['MD5']}`
- date: {T['DATE']}

| metric | cr | or | ratio |
|---|---|---|---|
| wall .fa (s) | {wall['cr-fa']:.3f} | {wall['or-fa']:.3f} | {rt(wall['cr-fa'],wall['or-fa'])} |
| wall .gz (s) | {wall['cr-gz']:.3f} | {wall['or-gz']:.3f} | {rt(wall['cr-gz'],wall['or-gz'])} |
| peak RSS (MB) | {mem.get('cr',0):.1f} | {mem.get('or',0):.1f} | {rt(mem.get('cr',0),mem.get('or',1))} |
| instructions | {insn('ps_cr.txt')} | {insn('ps_or.txt')} | |
| normalize alloc (MB) | {norm} | — | |
| core total alloc (MB) | {core} | — | |

hottest fn (cr): `{top}`
""")
PY

say "saved $OUT"
cat "$OUT"

#!/usr/bin/env bash
# STEP 4 — WHERE the allocations happen (the key insight tool).
# Peak RSS tells you "how much"; it does not tell you "from which line".
# bench_core.cr calls the library directly, excludes file I/O and output from the
# measured region, and reads GC.stats before/after to attribute bytes to:
#   - normalize_sequence alone
#   - the full core (= normalize + the windowing algorithm)
# The difference reveals that the algorithm itself allocates almost nothing.
source "$(dirname "$0")/_common.sh"
need crystal

hr "build bench_core (release)"
if ! crystal build --release "$SCRIPT_DIR/bench_core.cr" -o "$SCRIPT_DIR/bench_core" >"$RESULTS/build.log" 2>&1; then
  echo "[!] build failed:"; cat "$RESULTS/build.log"; exit 1
fi
echo "built (warnings, if any, in $RESULTS/build.log)"

hr "allocation breakdown via GC.stats"
"$SCRIPT_DIR/bench_core" "$FA" "$W" "$T" | tee "$RESULTS/alloc.txt"

# Bonus: Boehm GC's own stats from the REAL binary, no source changes needed.
hr "GC_PRINT_STATS on the real sdust-cr (tail)"
GC_PRINT_STATS=1 "$CR" -w "$W" -t "$T" "$FA" >/dev/null 2>"$RESULTS/gc_print.txt" || true
tail -n 8 "$RESULTS/gc_print.txt" || true

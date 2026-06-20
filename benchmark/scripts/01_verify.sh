#!/usr/bin/env bash
# STEP 1 — Verify the two implementations produce IDENTICAL output.
# Why: a speed/memory comparison is only meaningful if both do the same work.
# If this fails, STOP — fix correctness before benchmarking.
source "$(dirname "$0")/_common.sh"

hr "diff sdust-cr vs sdust-or on $CHROM (w=$W t=$T)"
"$CR" -w "$W" -t "$T" "$FA" 2>/dev/null > "$RESULTS/out_cr.txt"
"$OR" -w "$W" -t "$T" "$FA" 2>/dev/null > "$RESULTS/out_or.txt"

echo "lines: cr=$(wc -l < "$RESULTS/out_cr.txt")  or=$(wc -l < "$RESULTS/out_or.txt")"
if diff -q "$RESULTS/out_cr.txt" "$RESULTS/out_or.txt" >/dev/null; then
  echo "[OK] outputs are identical"
else
  echo "[FAIL] outputs differ:"; diff "$RESULTS/out_cr.txt" "$RESULTS/out_or.txt" | head -20
  exit 1
fi

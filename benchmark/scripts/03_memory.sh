#!/usr/bin/env bash
# STEP 3 — Peak memory (peak RSS) of each whole process.
# Why this and not `time -v`: /usr/bin/time is often absent. maxrss.py asks the
# kernel for the child's ru_maxrss via getrusage — portable and exact.
# peak RSS is the number a user feels ("it ate N MB"). We run twice because GC
# makes it slightly non-deterministic.
source "$(dirname "$0")/_common.sh"
need python3

hr "peak RSS (2 rounds)"
for round in 1 2; do
  python3 "$SCRIPT_DIR/maxrss.py" "$CR" -w "$W" -t "$T" "$FA"
  python3 "$SCRIPT_DIR/maxrss.py" "$OR" -w "$W" -t "$T" "$FA"
  python3 "$SCRIPT_DIR/maxrss.py" "$CR" -w "$W" -t "$T" "$GZ"
  python3 "$SCRIPT_DIR/maxrss.py" "$OR" -w "$W" -t "$T" "$GZ"
  echo "---"
done | tee "$RESULTS/memory.txt"

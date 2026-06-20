#!/usr/bin/env bash
# Run the whole pipeline in order. Each step is independent and re-runnable.
# Usage:  ./run_all.sh                 # defaults (chr21, w64 t20)
#         CHROM=chr1 RUNS=3 ./run_all.sh
source "$(dirname "$0")/_common.sh"

[ -f "$FA" ] || "$SCRIPT_DIR/00_prepare.sh"   # build subset only if missing
"$SCRIPT_DIR/01_verify.sh"                     # correctness gate
"$SCRIPT_DIR/02_wall.sh"                       # speed
"$SCRIPT_DIR/03_memory.sh"                     # peak RSS
"$SCRIPT_DIR/04_alloc.sh"                      # allocation attribution
"$SCRIPT_DIR/05_perf.sh"                       # CPU hotspots

hr "done — raw outputs in $RESULTS"

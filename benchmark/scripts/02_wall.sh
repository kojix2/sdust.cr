#!/usr/bin/env bash
# STEP 2 — Wall-clock time with hyperfine.
# Why hyperfine: it warms up, repeats, and reports mean ± stddev (one run lies).
# We test BOTH .fa and .gz so we can separate gzip-decompression cost from the
# algorithm: (cr_gz - cr_fa) is roughly the gzip overhead.
source "$(dirname "$0")/_common.sh"
need hyperfine

hr "wall clock — plain .fa"
hyperfine --warmup "$WARMUP" --runs "$RUNS" --export-json "$RESULTS/wall_fa.json" \
  -n "cr-fa" "$CR -w $W -t $T $FA" \
  -n "or-fa" "$OR -w $W -t $T $FA" 2>/dev/null

hr "wall clock — gzip .gz"
hyperfine --warmup "$WARMUP" --runs "$RUNS" --export-json "$RESULTS/wall_gz.json" \
  -n "cr-gz" "$CR -w $W -t $T $GZ" \
  -n "or-gz" "$OR -w $W -t $T $GZ" 2>/dev/null

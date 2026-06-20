#!/usr/bin/env bash
# STEP 0 — Build a small, fast-to-iterate SUBSET of the data.
# Why: profiling needs many quick repetitions; the full 3 GB genome is too slow.
# We extract one chromosome (default chr21, ~47 Mbp) as plain .fa and bgzip .gz.
source "$(dirname "$0")/_common.sh"
need samtools; need bgzip

[ -f "$FULL_FA" ] || { echo "[!] $FULL_FA not found. Run 'make data' first." >&2; exit 1; }

hr "extract $CHROM"
samtools faidx "$FULL_FA" "$CHROM" > "$FA"
samtools faidx "$FA"

hr "bgzip copy"
bgzip -k -f "$FA"
samtools faidx "$GZ"

hr "result"
ls -lah "$FA" "$GZ"
cat "$FA.fai"

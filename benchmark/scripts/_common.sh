#!/usr/bin/env bash
# Shared paths + configuration for the benchmark scripts.
# Source this from every script:  source "$(dirname "$0")/_common.sh"
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCH_DIR="$(dirname "$SCRIPT_DIR")"          # .../benchmark
ROOT_DIR="$(dirname "$BENCH_DIR")"            # repo root

# --- knobs (override on the command line, e.g. CHROM=chr1 ./02_wall.sh) ---
CHROM="${CHROM:-chr21}"          # which subset sequence to use
W="${W:-64}"                     # sdust window size
T="${T:-20}"                     # sdust threshold
RUNS="${RUNS:-5}"                # hyperfine runs
WARMUP="${WARMUP:-1}"            # hyperfine warmups

# --- derived paths ---
FULL_FA="$BENCH_DIR/data/JG3.0.0.fa"
FA="$BENCH_DIR/data/$CHROM.fa"
GZ="$BENCH_DIR/data/$CHROM.fa.gz"
CR="$BENCH_DIR/bin/sdust-cr"
OR="$BENCH_DIR/bin/sdust-or"
RESULTS="$BENCH_DIR/results"
mkdir -p "$RESULTS"

# Abort early with a clear message if a tool is missing.
need() { command -v "$1" >/dev/null 2>&1 || { echo "[!] missing tool: $1" >&2; exit 127; }; }

# Pretty section header.
hr() { printf '\n=== %s ===\n' "$*"; }

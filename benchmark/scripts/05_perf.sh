#!/usr/bin/env bash
# STEP 5 — CPU profile with perf.
# `perf stat`  : counters (instructions, cycles, IPC, page-faults). Comparing cr
#                vs or here tells you if Crystal runs MORE instructions and/or
#                stalls more. page-faults correlates with extra memory traffic.
# `perf record`: sampling profiler -> which FUNCTION burns the cycles (self%).
# Binaries are built with debug info, so symbol names resolve.
source "$(dirname "$0")/_common.sh"
need perf

hr "perf stat — sdust-cr"
perf stat -- "$CR" -w "$W" -t "$T" "$FA" >/dev/null 2>"$RESULTS/perf_stat_cr.txt"
grep -E "instructions|cpu-cycles|insn per|page-faults|task-clock|elapsed" "$RESULTS/perf_stat_cr.txt" || cat "$RESULTS/perf_stat_cr.txt"

hr "perf stat — sdust-or"
perf stat -- "$OR" -w "$W" -t "$T" "$FA" >/dev/null 2>"$RESULTS/perf_stat_or.txt"
grep -E "instructions|cpu-cycles|insn per|page-faults|task-clock|elapsed" "$RESULTS/perf_stat_or.txt" || cat "$RESULTS/perf_stat_or.txt"

hr "perf record — sdust-cr (top self symbols)"
perf record -g -o "$RESULTS/perf_cr.data" -- "$CR" -w "$W" -t "$T" "$FA" >/dev/null 2>/dev/null
perf report -i "$RESULTS/perf_cr.data" --stdio --no-children 2>/dev/null \
  | grep -E "^\s+[0-9]" | head -15 | tee "$RESULTS/perf_report_cr.txt"

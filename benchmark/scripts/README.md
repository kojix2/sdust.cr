# benchmark/scripts

Small, single-purpose, re-runnable scripts to compare `sdust-cr` (Crystal) with
`sdust-or` (original C). Run them in order to reproduce [../ANALYSIS.md](../ANALYSIS.md).

## Quick start

```sh
make -C .. data        # download data (first time only)
./run_all.sh           # runs 00..05 (default: chr21, w64 t20)

CHROM=chr1 RUNS=3 ./run_all.sh   # override via env vars
```

Run steps alone too (`./02_wall.sh`). Outputs go to `../results/`.

## Files

| File | Job | Tool |
|---|---|---|
| `_common.sh` | Shared paths and config (CHROM/W/T/RUNS) | — |
| `00_prepare.sh` | Extract one chromosome as `.fa`/`.gz` for fast iteration | samtools, bgzip |
| `01_verify.sh` | Check both impls give identical output | diff |
| `02_wall.sh` | Wall-clock time; `.fa` vs `.gz` isolates gzip cost | hyperfine |
| `03_memory.sh` | Peak RSS of the whole process | maxrss.py |
| `04_alloc.sh` | Attribute allocations to code via GC.stats | bench_core.cr |
| `05_perf.sh` | CPU counters + hottest functions | perf |
| `maxrss.py` | Run a command, report child peak RSS (getrusage) | — |
| `bench_core.cr` | Call the library directly, exclude I/O, measure bytes | — |

## Method

Principles:
1. Measure, don't guess. Hotspots surprise you.
2. Compare the same work first (`01`), or the rest is meaningless.
3. One run lies: warm up, repeat, report stddev (hyperfine does this).
4. Split the layers: I/O, gzip, normalize, core, output.
   - gzip cost ≈ `cr_gz − cr_fa`
   - normalize/core allocation ≈ `bench_core.cr` (I/O excluded)
5. "How much" and "where" need different tools.

What each tool answers:
- **hyperfine** — how fast, with variance.
- **getrusage / maxrss.py** — peak MB the user feels.
- **GC.stats (bench_core)** — which code allocated the extra memory. *Key here.*
- **perf stat** — more instructions, or more stalls? (cr vs or)
- **perf record** — which function burns the cycles (self%).
- **GC_PRINT_STATS=1** (`04` bonus) — real-binary GC behavior, no code change.

How it read out for this project:
- `02`: only +5% slower → speed is probably not the core compute.
- `03`: memory 3–4× → this is the real problem.
- `04`: most extra memory is `normalize_sequence` allocating a full-length array.
- `05`: core matches C (93% in the main loop, GC <0.2% of CPU).
→ Not "Crystal is heavy" but an implementation-design issue.

## Requirements
`samtools`, `bgzip`, `hyperfine`, `perf`, `python3`, `crystal`.
Each script checks for missing tools at startup (`need` in `_common.sh`).

## Notes
- Both binaries are `--release` (rebuild with `make -C .. build`).
- `bench_core` and `results/*.data` are regenerated; keep them out of git.

# benchmark/scripts

Compare `sdust-cr` (Crystal) with `sdust-or` (original C).

```sh
make -C .. data        # download data (first time only)
./bench.sh             # run everything; saves results/<git-tag>.md
CHROM=chr1 ./bench.sh v0.1.6   # override subset / name
```

`bench.sh` does, in order:

1. **prepare** — extract one chromosome (default chr21) if missing.
2. **verify** — both impls must produce identical output, else abort.
3. **wall** — hyperfine on `.fa` and `.gz` (gzip cost = cr-gz − cr-fa).
4. **peak RSS** — `maxrss.py` (getrusage), what the user feels.
5. **allocation** — `bench_core.cr` + `GC.stats`: which code allocates the extra memory.
6. **perf** — instruction counts (cr vs or) and the hottest function.

It prints a summary and writes it to `results/<TAG>.md`.

## Compare versions

```sh
diff results/v0.1.5.alpha.md results/v0.1.6.md
```

Only `results/*.md` is kept (gitignored otherwise). Intermediate files
(perf.data, output dumps, the bench_core binary) are built in a temp dir and deleted.

## Files
- `bench.sh` — the whole pipeline.
- `maxrss.py` — run a command, report child peak RSS.
- `bench_core.cr` — call the library directly, exclude I/O, measure allocations.

Needs: `samtools`, `bgzip`, `hyperfine`, `perf`, `python3`, `crystal`.
Both binaries are `--release` (rebuild: `make -C .. build`).

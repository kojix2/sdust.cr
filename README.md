# Sdust.cr

[![test](https://github.com/kojix2/sdust.cr/actions/workflows/test.yml/badge.svg)](https://github.com/kojix2/sdust.cr/actions/workflows/test.yml)

Reimplementation of [Sdust](https://github.com/lh3/sdust) in [Crystal](https://crystal-lang.org/).

- [symmetric DUST algorithm](https://pubmed.ncbi.nlm.nih.gov/16796549/)

## Installation

Install via [GitHub Releases](https://github.com/kojix2/sdust.cr/releases) or from source:

```sh
git clone https://github.com/kojix2/sdust.cr
cd sdust.cr
shards build --release
```

To enable parallel processing with `--threads`, build with Crystal's execution
context preview flags:

```console
shards build --release -Dpreview_mt -Dexecution_context
```

## Usage

```
Usage: sdust [options] <in.fa>
    -w, --window SIZE                Window size [64]
    -t, --threshold SIZE             Threshold size [20]
    -@, --threads COUNT              Worker threads [1]
```

By default, sdust streams FASTA records and does not keep whole contigs in
memory. With `--threads` greater than 1, records are processed in parallel by
contig. This can use much more memory because each worker buffers a whole
contig before processing it. Use `--threads 0` to use all available workers.

## License

- This project is a reimplementation of Heng Li's [Sdust](https://github.com/lh3/sdust) in Crystal.
- Sdust is part of [Minimap2](https://github.com/lh3/minimap2), which is licensed under the [MIT License](https://github.com/lh3/minimap2/blob/master/LICENSE.txt).

MIT License

## FAQ

Q: Is this implementation faster than the original Sdust?

A: No. Earlier versions were about 1.5x slower. In the v0.2.0 benchmark, after streaming FASTA records through the core and reducing some allocations, it is about 1.04x slower on chr21.

Q: Does this implementation consume less memory than the original Sdust?

A: In the v0.2.0 benchmark, yes. Earlier versions used several times more memory. After reducing retained sequence and intermediate data, peak RSS on chr21 is lower than the original Sdust.

Q: Why was it created?

A: It was created to explore how much performance could be improved using Crystal, a language similar to Ruby.

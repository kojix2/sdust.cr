# Sdust.cr

[![test](https://github.com/kojix2/sdust.cr/actions/workflows/test.yml/badge.svg)](https://github.com/kojix2/sdust.cr/actions/workflows/test.yml)

Reimplementation of [Sdust](https://github.com/lh3/sdust) in Crystal.

## Installation

Install via [GitHub Releases](https://github.com/kojix2/sdust.cr/releases) or from source:

```sh
git clone https://github.com/kojix2/sdust.cr
cd sdust.cr
shards build --release
```

## Usage

```
  Usage: sdust [options] <in.fa>
    -w, --window SIZE                Specify the window size
    -t, --threshold SIZE             Specify the threshold size
```

Experimental multi-threading is available with the `-Dpreview_mt` option.

```sh
git clone https://github.com/kojix2/sdust.cr
cd sdust.cr
shards build --release -Dpreview_mt
```

Set the number of threads with the `CRYSTAL_WORKERS` environment variable.

```sh
CRYSTAL_WORKERS=4 sdust -w 64 -t 20 chrM.fa
```

This enables parallel processing for each sequence within a FASTA file.

## 

## License

- This project is a reimplementation of Heng Li's [Sdust](https://github.com/lh3/sdust) in Crystal.
- Sdust is part of [Minimap2](https://github.com/lh3/minimap2), which is licensed under the [MIT License](https://github.com/lh3/minimap2/blob/master/LICENSE.txt).

MIT License

## FAQ

Q: Is this implementation faster than the original Sdust?
A: No, it's about 1.5 times slower. However, it becomes quite fast when multi-threading is enabled. 

Q: Does this implementation consume more memory than the original Sdust?
A: No, it seems to consume about 5 times more memory. Memory consumption increases further when multi-threading is enabled.

Q: Why was it created?
A: It was created to explore how much performance could be improved using Crystal, a language similar to Ruby.

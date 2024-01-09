# Sdust.cr

[![test](https://github.com/kojix2/sdust.cr/actions/workflows/test.yml/badge.svg)](https://github.com/kojix2/sdust.cr/actions/workflows/test.yml)
[![build](https://github.com/kojix2/sdust.cr/actions/workflows/build.yml/badge.svg)](https://github.com/kojix2/sdust.cr/actions/workflows/build.yml)

Reimplementation of [Sdust](https://github.com/lh3/sdust) in [Crystal](https://crystal-lang.org/).

- [symmetric DUST algorithm](https://pubmed.ncbi.nlm.nih.gov/16796549/)

## Installation

Install via [GitHub Releases](https://github.com/kojix2/sdust.cr/releases) or from source:

```sh
git clone https://github.com/kojix2/sdust.cr
cd sdust.cr
shards build --release
# shards build --release -Dpreview_mt # enable multi-threading
```

## Usage

```
Usage: sdust [options] <in.fa>
    -w, --window SIZE                Window size [64]
    -t, --threshold SIZE             Threshold size [20]
    -@, --threads INT                Number of threads [4]
```

## License

- This project is a reimplementation of Heng Li's [Sdust](https://github.com/lh3/sdust) in Crystal.
- Sdust is part of [Minimap2](https://github.com/lh3/minimap2), which is licensed under the [MIT License](https://github.com/lh3/minimap2/blob/master/LICENSE.txt).

MIT License

## FAQ

Q: Is this implementation faster than the original Sdust?

A: No, it's about 1.5 times slower. However, it becomes quite fast when multi-threading is enabled.

Q: Does this implementation consume less memory than the original Sdust?

A: No, it appears to consume about 5 times more memory. Enabling multi-threading further increases the consumption.

Q: Why was it created?

A: It was created to explore how much performance could be improved using Crystal, a language similar to Ruby.

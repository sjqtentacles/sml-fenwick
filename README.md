# sml-fenwick

[![CI](https://github.com/sjqtentacles/sml-fenwick/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-fenwick/actions/workflows/ci.yml)

Fenwick trees (Binary Indexed Trees) and a lazy-propagation segment tree in
pure Standard ML — O(log n) point updates, prefix/range sums, cumulative
search, and range-add/range-sum, with a **persistent** (copy-on-update) API.

No dependencies, no FFI, no threads, no clock, no randomness: the same inputs
always produce the same outputs under **MLton** and **Poly/ML**. Every update
returns a new tree and never mutates its argument, so old versions stay valid.

- **`Fenwick.Bit`** — a Fenwick tree / BIT: `prefixSum`, `rangeSum`, `update`,
  `set`, `total`, and `lowerBound` (binary lifting for cumulative-frequency
  search over non-negative data).
- **`Fenwick.Seg`** — a segment tree with lazy propagation: `rangeAdd` and
  `rangeSum` in O(log n), plus `pointSet`/`get` built on top.

All indices are 0-based; ranges are inclusive `[lo, hi]`.

## API

```sml
structure Fenwick : sig
  structure Bit : sig
    type t
    val make      : int -> t                 (* n zeros, indices 0..n-1 *)
    val fromList  : int list -> t
    val size      : t -> int
    val get       : t -> int -> int
    val update    : t -> int -> int -> t      (* add delta at index i *)
    val set       : t -> int -> int -> t
    val prefixSum : t -> int -> int           (* sum of [0..i]; i<0 -> 0 *)
    val rangeSum  : t -> int -> int -> int
    val total     : t -> int
    val toList    : t -> int list
    val lowerBound : t -> int -> int          (* smallest i with prefixSum i >= target *)
  end
  structure Seg : sig
    type t
    val make     : int -> t
    val fromList : int list -> t
    val size     : t -> int
    val get      : t -> int -> int
    val pointSet : t -> int -> int -> t
    val rangeAdd : t -> int -> int -> int -> t  (* add delta to [lo..hi] *)
    val rangeSum : t -> int -> int -> int
    val total    : t -> int
    val toList   : t -> int list
  end
end
```

## Example

```sml
val b = Fenwick.Bit.fromList [1,2,3,4,5,6,7,8,9,10]
val 10 = Fenwick.Bit.prefixSum b 3         (* 1+2+3+4 *)
val 18 = Fenwick.Bit.rangeSum b 2 5         (* 3+4+5+6 *)
val 3  = Fenwick.Bit.lowerBound b 10        (* first index whose prefix >= 10 *)
val b' = Fenwick.Bit.update b 4 100         (* persistent: b is unchanged *)

val sg  = Fenwick.Seg.fromList [3,1,4,1,5,9,2,6]
val sg2 = Fenwick.Seg.rangeAdd sg 1 4 10    (* add 10 to indices 1..4 *)
val 40  = Fenwick.Seg.rangeSum sg2 2 4
```

Running [`examples/demo.sml`](examples/demo.sml) with `make example` prints:

```
Fenwick tree (BIT) over [1,2,3,4,5,6,7,8,9,10]:
  prefixSum[0..0] = 1
  prefixSum[0..3] = 10
  prefixSum[0..6] = 28
  prefixSum[0..9] = 55
  rangeSum[2..5]      = 18
  lowerBound(30)      = idx 7
  after +100 at idx 4, total 55 -> 155

Lazy segment tree over [3,1,4,1,5,9,2,6]:
  rangeSum[0..7]      = 31
  rangeAdd 10 to [1..4]; rangeSum[2..4]: 10 -> 40
  values now          = [3,11,14,11,15,9,2,6]
```

## Build & test

Requires [MLton](http://mlton.org/) and/or [Poly/ML](https://polyml.org/).

```sh
make test        # build + run the suite under MLton
make test-poly   # run the suite under Poly/ML
make all-tests   # both
make example     # build + run the demo
make clean
```

## Installing with smlpkg

```sh
smlpkg add github.com/sjqtentacles/sml-fenwick
smlpkg sync
```

Reference `lib/github.com/sjqtentacles/sml-fenwick/fenwick.mlb` from your own
`.mlb` (MLton / MLKit), or feed `sources.mlb` to `tools/polybuild` (Poly/ML).

## Layout

```
sml.pkg                                       smlpkg manifest
Makefile                                      MLton + Poly/ML targets
.github/workflows/ci.yml                      CI: MLton + Poly/ML
lib/github.com/sjqtentacles/sml-fenwick/
  fenwick.sig    FENWICK signature
  fenwick.sml    Bit + Seg implementation
  sources.mlb    ordered source list
  fenwick.mlb    public basis
examples/
  demo.sml       Fenwick + segment-tree walkthrough
test/
  harness.sml    shared assertion harness
  test.sml       prefix/range/lowerBound + lazy range-add vectors (46 checks)
  entry.sml / main.sml
tools/polybuild  Poly/ML build wrapper
```

## Tests

46 deterministic checks against fixed integer arrays: Fenwick prefix sums
(`1,3,6,10,…,55`) cross-checked against a naive prefix, range sums, persistent
`update`/`set`, and `lowerBound` cumulative search at every boundary; lazy
segment-tree range-add/range-sum with layered overlapping updates, `pointSet`,
and persistence (originals never mutate). Run `make all-tests` to verify
identical output under both compilers.

## License

MIT. See [LICENSE](LICENSE).

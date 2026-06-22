(* fenwick.sig

   Fenwick trees (Binary Indexed Trees) and a lazy-propagation segment tree,
   in pure Standard ML.

   Both structures are *persistent* at the API level: every update returns a
   new tree and never mutates the argument (internally a fresh array is copied
   per update, so old values remain valid). All indices are 0-based and
   half-open ranges are written as inclusive [lo, hi]. Values are the default
   `int`. No FFI, threads, clock or randomness: the same inputs always produce
   the same outputs under MLton and Poly/ML.

   `Bit` is a Fenwick tree supporting O(log n) point updates and prefix/range
   sums, plus `lowerBound` (binary lifting) for cumulative-frequency search.

   `Seg` is a segment tree with lazy propagation supporting O(log n) range-add
   and range-sum (and point get/set built on top). *)

signature FENWICK =
sig
  (* ---- Fenwick tree / Binary Indexed Tree ---- *)
  structure Bit :
  sig
    type t
    val make      : int -> t                 (* n zeros, indices 0..n-1 *)
    val fromList  : int list -> t
    val size      : t -> int
    val get       : t -> int -> int          (* value at index i *)
    val update    : t -> int -> int -> t      (* add delta at index i *)
    val set       : t -> int -> int -> t      (* set index i to value *)
    val prefixSum : t -> int -> int           (* sum of [0..i]; i<0 -> 0 *)
    val rangeSum  : t -> int -> int -> int     (* sum of [lo..hi] inclusive *)
    val total     : t -> int                  (* sum of everything *)
    val toList    : t -> int list
    (* smallest index i such that prefixSum i >= target (cumulative search);
       assumes non-negative values. Returns `size` if no such index. *)
    val lowerBound : t -> int -> int
  end

  (* ---- Segment tree with lazy propagation (range add, range sum) ---- *)
  structure Seg :
  sig
    type t
    val make     : int -> t                  (* n zeros *)
    val fromList : int list -> t
    val size     : t -> int
    val get      : t -> int -> int
    val pointSet : t -> int -> int -> t
    val rangeAdd : t -> int -> int -> int -> t  (* add delta to [lo..hi] *)
    val rangeSum : t -> int -> int -> int        (* sum over [lo..hi] *)
    val total    : t -> int
    val toList   : t -> int list
  end
end

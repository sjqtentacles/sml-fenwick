(* fenwick.sml - Fenwick tree (BIT) + lazy segment tree.

   Internally array-backed; every public update copies the backing array(s)
   first, so trees are persistent values (sharing nothing mutable). *)

structure Fenwick :> FENWICK =
struct

  fun copy a = Array.tabulate (Array.length a, fn i => Array.sub (a, i))

  (* ---------------------------------------------------------------- *)
  structure Bit =
  struct
    (* tree is 1-indexed of length n+1; n is the logical size. *)
    type t = { n : int, tree : int array }

    fun size ({ n, ... } : t) = n

    (* lowbit via two's-complement on Word (Int has no bitwise ops). *)
    fun lowbit i =
      let val w = Word.fromInt i
      in Word.toInt (Word.andb (w, Word.~ w)) end

    (* in-place add of delta at 1-based index i, walking up the tree. *)
    fun addAt (tree, n, i, delta) =
      let
        fun go i =
          if i > n then ()
          else (Array.update (tree, i, Array.sub (tree, i) + delta);
                go (i + lowbit i))
      in go i end

    fun make n =
      if n < 0 then raise Subscript
      else { n = n, tree = Array.array (n + 1, 0) }

    fun fromList xs =
      let
        val n = List.length xs
        val tree = Array.array (n + 1, 0)
        val _ = List.foldl (fn (v, i) => (addAt (tree, n, i + 1, v); i + 1)) 0 xs
      in { n = n, tree = tree } end

    (* sum of logical [0..i] == internal prefix to (i+1). *)
    fun prefixSum ({ tree, ... } : t) i =
      let
        fun go (j, acc) = if j <= 0 then acc
                          else go (j - lowbit j, acc + Array.sub (tree, j))
      in if i < 0 then 0 else go (i + 1, 0) end

    fun rangeSum t lo hi =
      if hi < lo then 0
      else prefixSum t hi - prefixSum t (lo - 1)

    fun get t i = rangeSum t i i

    fun total (t as { n, ... } : t) = prefixSum t (n - 1)

    fun update ({ n, tree } : t) i delta =
      if i < 0 orelse i >= n then raise Subscript
      else
        let val tree' = copy tree
        in addAt (tree', n, i + 1, delta); { n = n, tree = tree' } end

    fun set t i v = update t i (v - get t i)

    fun toList (t as { n, ... } : t) = List.tabulate (n, fn i => get t i)

    (* smallest 0-based index whose prefix sum >= target (non-negative data). *)
    fun lowerBound ({ n, tree } : t) target =
      if target <= 0 then 0
      else
        let
          (* highest power of two <= n *)
          fun hp p = if p * 2 <= n then hp (p * 2) else p
          val start = if n = 0 then 0 else hp 1
          fun go (pos, p, rem) =
            if p = 0 then pos
            else
              let val next = pos + p
              in
                if next <= n andalso Array.sub (tree, next) < rem
                then go (next, p div 2, rem - Array.sub (tree, next))
                else go (pos, p div 2, rem)
              end
          val pos = go (0, start, target)
        in pos (* pos == count of elements with cumulative < target; index = pos *)
        end
  end

  (* ---------------------------------------------------------------- *)
  structure Seg =
  struct
    (* tree/lazy are 1-indexed segment trees of length 4*max(n,1). *)
    type t = { n : int, tree : int array, lz : int array }

    fun size ({ n, ... } : t) = n

    fun alloc n = Array.array (4 * (if n < 1 then 1 else n), 0)

    fun applyNode (tree, lz, node, lo, hi, delta) =
      (Array.update (tree, node, Array.sub (tree, node) + delta * (hi - lo + 1));
       Array.update (lz, node, Array.sub (lz, node) + delta))

    fun pushDown (tree, lz, node, lo, hi) =
      let val d = Array.sub (lz, node)
      in
        if d <> 0 andalso lo <> hi then
          let val mid = (lo + hi) div 2
          in applyNode (tree, lz, node * 2, lo, mid, d);
             applyNode (tree, lz, node * 2 + 1, mid + 1, hi, d);
             Array.update (lz, node, 0)
          end
        else ()
      end

    fun buildFrom (arr : int array) =
      let
        val n = Array.length arr
        val tree = alloc n
        val lz = alloc n
        fun build (node, lo, hi) =
          if lo = hi then Array.update (tree, node, Array.sub (arr, lo))
          else
            let val mid = (lo + hi) div 2
            in build (node * 2, lo, mid);
               build (node * 2 + 1, mid + 1, hi);
               Array.update (tree, node,
                 Array.sub (tree, node * 2) + Array.sub (tree, node * 2 + 1))
            end
        val () = if n > 0 then build (1, 0, n - 1) else ()
      in { n = n, tree = tree, lz = lz } end

    fun make n = if n < 0 then raise Subscript else buildFrom (Array.array (n, 0))
    fun fromList xs = buildFrom (Array.fromList xs)

    fun rangeAddArr (tree, lz, n, l, r, delta) =
      let
        fun go (node, lo, hi) =
          if r < lo orelse hi < l then ()
          else if l <= lo andalso hi <= r then applyNode (tree, lz, node, lo, hi, delta)
          else
            let val mid = (lo + hi) div 2
            in pushDown (tree, lz, node, lo, hi);
               go (node * 2, lo, mid);
               go (node * 2 + 1, mid + 1, hi);
               Array.update (tree, node,
                 Array.sub (tree, node * 2) + Array.sub (tree, node * 2 + 1))
            end
      in if n > 0 then go (1, 0, n - 1) else () end

    fun rangeAdd ({ n, tree, lz } : t) lo hi delta =
      if lo > hi then { n = n, tree = copy tree, lz = copy lz }
      else if lo < 0 orelse hi >= n then raise Subscript
      else
        let val tree' = copy tree and lz' = copy lz
        in rangeAddArr (tree', lz', n, lo, hi, delta); { n = n, tree = tree', lz = lz' } end

    fun rangeSum ({ n, tree, lz } : t) l r =
      if l > r then 0
      else if l < 0 orelse r >= n then raise Subscript
      else
        let
          (* read-only query still pushes lazy into a scratch copy *)
          val tree' = copy tree and lz' = copy lz
          fun go (node, lo, hi) =
            if r < lo orelse hi < l then 0
            else if l <= lo andalso hi <= r then Array.sub (tree', node)
            else
              let val mid = (lo + hi) div 2
              in pushDown (tree', lz', node, lo, hi);
                 go (node * 2, lo, mid) + go (node * 2 + 1, mid + 1, hi)
              end
        in if n > 0 then go (1, 0, n - 1) else 0 end

    fun get t i = rangeSum t i i
    fun total (t as { n, ... } : t) = if n = 0 then 0 else rangeSum t 0 (n - 1)
    fun pointSet t i v = rangeAdd t i i (v - get t i)
    fun toList (t as { n, ... } : t) = List.tabulate (n, fn i => get t i)
  end
end

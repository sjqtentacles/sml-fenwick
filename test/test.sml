(* Tests for sml-fenwick: Fenwick tree (BIT) prefix/range sums + lowerBound,
   and lazy-propagation segment tree range-add/range-sum. Reference values are
   computed by hand against fixed integer arrays. *)

structure Tests =
struct
  open Harness
  structure B = Fenwick.Bit
  structure S = Fenwick.Seg

  (* naive prefix sum for cross-checking *)
  fun naivePrefix xs i =
    List.foldl op+ 0 (List.take (xs, i + 1))

  fun runAll () =
    let
      val xs = [1,2,3,4,5,6,7,8,9,10]
      val b = B.fromList xs

      val () = section "Bit: size / toList / get"
      val () = checkInt "size" (10, B.size b)
      val () = checkIntList "toList round-trips" (xs, B.toList b)
      val () = checkInt "get 0" (1, B.get b 0)
      val () = checkInt "get 9" (10, B.get b 9)

      val () = section "Bit: prefixSum"
      val () = checkInt "prefix ~1 -> 0" (0, B.prefixSum b ~1)
      val () = checkInt "prefix 0" (1, B.prefixSum b 0)
      val () = checkInt "prefix 3 (1+2+3+4)" (10, B.prefixSum b 3)
      val () = checkInt "prefix 9 (sum 1..10)" (55, B.prefixSum b 9)
      val () = check "prefix matches naive for all i"
                 (List.all (fn i => B.prefixSum b i = naivePrefix xs i)
                           (List.tabulate (10, fn i => i)))

      val () = section "Bit: rangeSum / total"
      val () = checkInt "range [2..5] (3+4+5+6)" (18, B.rangeSum b 2 5)
      val () = checkInt "range [0..9]" (55, B.rangeSum b 0 9)
      val () = checkInt "range [4..4]" (5, B.rangeSum b 4 4)
      val () = checkInt "empty range hi<lo" (0, B.rangeSum b 5 4)
      val () = checkInt "total" (55, B.total b)

      val () = section "Bit: update / set (persistent)"
      val b2 = B.update b 4 100      (* index 4: 5 -> 105 *)
      val () = checkInt "original unchanged after update" (5, B.get b 4)
      val () = checkInt "updated value" (105, B.get b2 4)
      val () = checkInt "updated total" (155, B.total b2)
      val b3 = B.set b 0 50
      val () = checkInt "set value" (50, B.get b3 0)
      val () = checkInt "set leaves others" (2, B.get b3 1)
      val () = checkInt "original still 1 after set" (1, B.get b 0)

      val () = section "Bit: lowerBound (cumulative search)"
      (* prefix sums: 1,3,6,10,15,21,28,36,45,55 *)
      val () = checkInt "target 1 -> idx 0" (0, B.lowerBound b 1)
      val () = checkInt "target 3 -> idx 1" (1, B.lowerBound b 3)
      val () = checkInt "target 4 -> idx 2" (2, B.lowerBound b 4)
      val () = checkInt "target 10 -> idx 3" (3, B.lowerBound b 10)
      val () = checkInt "target 11 -> idx 4" (4, B.lowerBound b 11)
      val () = checkInt "target 55 -> idx 9" (9, B.lowerBound b 55)
      val () = checkInt "target 56 -> size (none)" (10, B.lowerBound b 56)
      val () = checkInt "target 0 -> idx 0" (0, B.lowerBound b 0)

      val () = section "Bit: empty and singleton"
      val e = B.make 0
      val () = checkInt "empty size" (0, B.size e)
      val () = checkInt "empty total" (0, B.total e)
      val s1 = B.update (B.make 1) 0 7
      val () = checkInt "singleton" (7, B.get s1 0)

      (* ------------------- Segment tree ------------------- *)
      val () = section "Seg: build / get / total"
      val ys = [3,1,4,1,5,9,2,6]
      val sg = S.fromList ys
      val () = checkInt "size" (8, S.size sg)
      val () = checkIntList "toList round-trips" (ys, S.toList sg)
      val () = checkInt "rangeSum all (31)" (31, S.rangeSum sg 0 7)
      val () = checkInt "rangeSum [2..4] (4+1+5)" (10, S.rangeSum sg 2 4)
      val () = checkInt "total" (31, S.total sg)

      val () = section "Seg: rangeAdd (lazy) persistent"
      val sg2 = S.rangeAdd sg 1 4 10   (* add 10 to indices 1..4 *)
      val () = checkInt "original unchanged" (10, S.rangeSum sg 2 4)
      val () = checkInt "after rangeAdd [2..4]" (40, S.rangeSum sg2 2 4)
      val () = checkInt "after rangeAdd total (+40)" (71, S.total sg2)
      val () = checkInt "outside add unchanged [5..7]" (17, S.rangeSum sg2 5 7)
      val sg3 = S.rangeAdd (S.rangeAdd sg 0 7 1) 0 7 1  (* +2 everywhere *)
      val () = checkInt "double full add" (31 + 16, S.total sg3)

      val () = section "Seg: pointSet"
      val sg4 = S.pointSet sg 0 100
      val () = checkInt "pointSet value" (100, S.get sg4 0)
      val () = checkInt "pointSet total" (31 - 3 + 100, S.total sg4)
      val () = checkInt "original point unchanged" (3, S.get sg 0)

      val () = section "Seg: overlapping range adds"
      val a = S.make 5
      val a1 = S.rangeAdd a 0 2 5
      val a2 = S.rangeAdd a1 1 3 2
      (* values: [5,7,7,2,0] *)
      val () = checkIntList "layered adds" ([5,7,7,2,0], S.toList a2)
      val () = checkInt "rangeSum [1..3]" (16, S.rangeSum a2 1 3)

      val () = section "Bit: properties (sml-check, seed 0wx1)"
      val seed : Check.seed = 0wx1

      (* Generator: a nonempty list of small ints (values kept small so
         prefixSum/total can't overflow the default 32-bit int on MLton). *)
      val smallInt = Check.choose (~1000, 1000)
      val genList = Check.nonEmptyListOf smallInt

      fun showIntList xs = "[" ^ String.concatWith "," (List.map Int.toString xs) ^ "]"

      (* fromList xs then toList reproduces xs exactly. *)
      val () =
        Harness.check "prop: fromList/toList round-trips"
          (case Check.quickCheck
                  (Check.forAll genList showIntList
                     (fn xs => B.toList (B.fromList xs) = xs)) of
               Check.Passed _ => true
             | Check.Failed _ => false)

      (* prefixSum i always agrees with the naive reference sum. *)
      val () =
        Harness.check "prop: prefixSum matches naive prefix sum at every index"
          (case Check.quickCheck
                  (Check.forAll genList showIntList
                     (fn xs =>
                        let val b = B.fromList xs
                        in List.all (fn i => B.prefixSum b i = naivePrefix xs i)
                                    (List.tabulate (length xs, fn i => i))
                        end)) of
               Check.Passed _ => true
             | Check.Failed _ => false)

      (* total always equals prefixSum at the last index. *)
      val () =
        Harness.check "prop: total = prefixSum (size - 1)"
          (case Check.quickCheck
                  (Check.forAll genList showIntList
                     (fn xs =>
                        let val b = B.fromList xs
                        in B.total b = B.prefixSum b (B.size b - 1) end)) of
               Check.Passed _ => true
             | Check.Failed _ => false)

      (* update b i delta increases total by exactly delta, leaving every
         other index's value unchanged. *)
      val () =
        Harness.check "prop: update adds delta to total and only touches index i"
          (case Check.quickCheck
                  (Check.forAll
                     (Check.bind genList (fn xs =>
                        Check.bind (Check.choose (0, length xs - 1)) (fn i =>
                          Check.map (fn d => (xs, i, d))
                            (Check.choose (~500, 500)))))
                     (fn (xs, i, d) => showIntList xs ^ " i=" ^ Int.toString i
                                        ^ " d=" ^ Int.toString d)
                     (fn (xs, i, d) =>
                        let
                          val b = B.fromList xs
                          val b' = B.update b i d
                          val othersUnchanged =
                            List.all (fn j => j = i orelse B.get b' j = B.get b j)
                                     (List.tabulate (length xs, fn j => j))
                        in
                          B.total b' = B.total b + d
                          andalso B.get b' i = B.get b i + d
                          andalso othersUnchanged
                        end)) of
               Check.Passed _ => true
             | Check.Failed _ => false)
    in
      Harness.run ()
    end

  val run = runAll
end

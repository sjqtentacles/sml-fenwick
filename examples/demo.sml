(* demo.sml - cumulative-frequency table with a Fenwick tree, and a
   range-add / range-sum log with a lazy segment tree. Deterministic: identical
   output on every run and both compilers. *)

structure B = Fenwick.Bit
structure S = Fenwick.Seg

fun pad w s = if String.size s >= w then s
              else s ^ String.implode (List.tabulate (w - String.size s, fn _ => #" "))

val () = print "Fenwick tree (BIT) over [1,2,3,4,5,6,7,8,9,10]:\n"
val b = B.fromList [1,2,3,4,5,6,7,8,9,10]
val () =
  List.app
    (fn i => print ("  prefixSum[0.." ^ Int.toString i ^ "] = "
                    ^ Int.toString (B.prefixSum b i) ^ "\n"))
    [0,3,6,9]
val () = print ("  rangeSum[2..5]      = " ^ Int.toString (B.rangeSum b 2 5) ^ "\n")
val () = print ("  lowerBound(30)      = idx " ^ Int.toString (B.lowerBound b 30) ^ "\n")
val b' = B.update b 4 100
val () = print ("  after +100 at idx 4, total " ^ Int.toString (B.total b) ^ " -> "
                ^ Int.toString (B.total b') ^ "\n")

val () = print "\nLazy segment tree over [3,1,4,1,5,9,2,6]:\n"
val sg = S.fromList [3,1,4,1,5,9,2,6]
val () = print ("  rangeSum[0..7]      = " ^ Int.toString (S.rangeSum sg 0 7) ^ "\n")
val sg2 = S.rangeAdd sg 1 4 10
val () = print ("  rangeAdd 10 to [1..4]; rangeSum[2..4]: "
                ^ Int.toString (S.rangeSum sg 2 4) ^ " -> "
                ^ Int.toString (S.rangeSum sg2 2 4) ^ "\n")
val () = print ("  values now          = ["
                ^ String.concatWith "," (List.map Int.toString (S.toList sg2)) ^ "]\n")

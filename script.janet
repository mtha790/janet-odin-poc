# === Janet demonstration script for Odin integration ===

(print "=== Janet script start ===")

# Demo 1: Simple calculation
(print "\n--- Demo 1: Simple calculation ---")
(print "[Janet] Calling Odin function odin-calculate(10, 20)")
(def result1 (odin-calculate 10 20))
(print "[Janet] Result received from Odin:" result1)

# Processing in Janet
(def squared (* result1 result1))
(print "[Janet] Processed result (square):" squared)
(odin-process-result squared)

# Demo 2: More complex calculations
(print "\n--- Demo 2: Complex calculations ---")
(def values [5 15 25])
(print "[Janet] Processing array of values:" values)

(each val values
  (do
    (def odin-result (odin-calculate val val))
    (print "[Janet] " val " + " val " = " odin-result)

    # Janet calculation: cube of result
    (def cubed (* odin-result odin-result odin-result))
    (print "[Janet] Cube of " odin-result " = " cubed)

    (odin-process-result cubed)))

# Demo 3: Using Janet features
(print "\n--- Demo 3: Janet features ---")

# Custom Janet function
(defn process-with-janet [a b]
  "Janet function that uses Odin then processes the result"
  (def odin-sum (odin-calculate a b))
  (def janet-processed (+ (* odin-sum 2) 1))  # (sum * 2) + 1
  janet-processed)

(def final-result (process-with-janet 7 13))
(print "[Janet] Final result with Janet function:" final-result)
(odin-process-result final-result)

# Demo of Janet data structures
(print "\n--- Demo 4: Data structures ---")
(def calculations @{:addition (odin-calculate 5 3)
                    :multiplication (* 4 6)
                    :power (math/pow 2 8)})

(print "[Janet] Calculations table:" calculations)
(def sum-of-calculations (+ (calculations :addition)
                            (calculations :multiplication)
                            (calculations :power)))
(print "[Janet] Sum of calculations:" sum-of-calculations)
(odin-process-result sum-of-calculations)

(print "\n=== Janet script end ===")

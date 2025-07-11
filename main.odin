package main

import "core:fmt"

main :: proc() {
	fmt.println("=== Odin-Janet Bidirectional Integration Demo ===")

	// Initialize Janet environment
	env := init_janet()
	if env == nil {
		fmt.println("[Odin] Failed to initialize Janet")
		return
	}
	defer cleanup_janet()

	fmt.println("\n[Odin] Starting integration...")

	// Janet script demonstrating bidirectional interaction with variables
	janet_script := `
# === Janet script start ===
(print "[Janet] Janet script beginning")

# Call an Odin function to calculate 15 + 25
(print "[Janet] Calling Odin function odin-calculate(15, 25)")
(def result (odin-calculate 15 25))
(print "[Janet] Result received from Odin:" result)

# Processing in Janet - calculate square
(def processed (* result result))
(print "[Janet] Processed result (square):" processed)

# Create some variables that Odin can retrieve
(def my-number 42.5)
(def my-string "Hello from Janet!")
(def calculation-result processed)

(print "[Janet] Variables created:")
(print "[Janet]   my-number =" my-number)
(print "[Janet]   my-string =" my-string)
(print "[Janet]   calculation-result =" calculation-result)

(print "[Janet] Janet script end")
`


	// Execute the Janet script
	success := run_janet_string(env, janet_script)
	if success {
		fmt.println("\n[Odin] Janet script executed successfully!")

		// Retrieve variables directly from Janet environment
		fmt.println("\n[Odin] Retrieving Janet variables:")

		// Retrieve a number
		if number, found := get_janet_number(env, "my-number"); found {
			fmt.printf("[Odin] Variable 'my-number': %.2f\n", number)
		} else {
			fmt.println("[Odin] Variable 'my-number' not found or not a number")
		}

		// Retrieve a string
		if str, found := get_janet_string(env, "my-string"); found {
			fmt.printf("[Odin] Variable 'my-string': %s\n", str)
		} else {
			fmt.println("[Odin] Variable 'my-string' not found or not a string")
		}

		// Retrieve the calculation result
		if calc_result, found := get_janet_number(env, "calculation-result"); found {
			fmt.printf("[Odin] Variable 'calculation-result': %.2f\n", calc_result)
		} else {
			fmt.println("[Odin] Variable 'calculation-result' not found")
		}

		// Try to retrieve a variable that doesn't exist
		if _, found := get_janet_number(env, "nonexistent-var"); !found {
			fmt.println("[Odin] Variable 'nonexistent-var' not found (as expected)")
		}

	} else {
		fmt.println("\n[Odin] Error executing Janet script")
	}

	fmt.println("\n=== End of demonstration ===")
}

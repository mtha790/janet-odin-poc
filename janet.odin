package main

import "base:runtime"
import "core:c"
import "core:fmt"

// === Janet Types ===

Janet :: struct {
	type_and_flags: u64,
	data:           struct #raw_union {
		number:  f64,
		pointer: rawptr,
		integer: i64,
	},
}

Janet_Type :: enum i32 {
	NIL = 0,
	BOOLEAN,
	NUMBER,
	STRING,
	SYMBOL,
	KEYWORD,
	ARRAY,
	TUPLE,
	TABLE,
	STRUCT,
	BUFFER,
	FUNCTION,
	CFUNCTION,
	FIBER,
	POINTER,
	ABSTRACT,
}

Janet_Table :: struct {} // Opaque
Janet_String :: struct {} // Opaque  
Janet_Function :: struct {} // Opaque
Janet_Fiber :: struct {} // Opaque

// Global variable to store the final result
global_result_janet: f64 = 0

// === Janet C API Bindings ===

foreign import libjanet "system:janet"

foreign libjanet {
	janet_init :: proc "c" () ---
	janet_deinit :: proc "c" () ---
	janet_core_env :: proc "c" (flags: i32) -> ^Janet_Table ---

	janet_dostring :: proc "c" (env: ^Janet_Table, str: cstring, sourcePath: cstring, out: ^Janet) -> i32 ---

	janet_wrap_nil :: proc "c" () -> Janet ---
	janet_wrap_number :: proc "c" (x: f64) -> Janet ---
	janet_wrap_cfunction :: proc "c" (cfun: proc "c" (argc: i32, argv: ^Janet) -> Janet) -> Janet ---
	janet_wrap_string :: proc "c" (str: cstring) -> Janet ---

	janet_unwrap_number :: proc "c" (x: Janet) -> f64 ---
	janet_unwrap_string :: proc "c" (x: Janet) -> cstring ---
	janet_checktype :: proc "c" (x: Janet, type: Janet_Type) -> i32 ---
	janet_type :: proc "c" (x: Janet) -> Janet_Type ---

	janet_def :: proc "c" (env: ^Janet_Table, name: cstring, val: Janet, documentation: cstring) ---
	janet_get :: proc "c" (ds: Janet, key: Janet) -> Janet ---
	janet_resolve :: proc "c" (env: ^Janet_Table, sym: Janet) -> Janet ---

	janet_panic :: proc "c" (message: cstring) ---
	janet_panicf :: proc "c" (fmt: cstring, #c_vararg args: ..any) ---
}

// === Odin Functions Exposed to Janet ===

// Odin function exposed to Janet - calculates the sum of two numbers
odin_calculate_c :: proc "c" (argc: i32, argv: ^Janet) -> Janet {
	context = runtime.default_context()

	if argc != 2 {
		janet_panicf("odin-calculate expects 2 arguments, got %d", argc)
		return janet_wrap_nil()
	}

	// Convert argv to slice to access elements
	args := ([^]Janet)(argv)[:argc]

	// Check that arguments are numbers
	if janet_checktype(args[0], .NUMBER) == 0 || janet_checktype(args[1], .NUMBER) == 0 {
		janet_panic("odin-calculate expects numeric arguments")
		return janet_wrap_nil()
	}

	// Get the arguments
	a := janet_unwrap_number(args[0])
	b := janet_unwrap_number(args[1])

	// Calculate the sum
	result := a + b

	fmt.printf("[Odin] odin-calculate called with a=%.2f, b=%.2f, result=%.2f\n", a, b, result)

	// Return the result
	return janet_wrap_number(result)
}

// Odin callback function exposed to Janet - receives processed result
odin_process_result_c :: proc "c" (argc: i32, argv: ^Janet) -> Janet {
	context = runtime.default_context()

	if argc != 1 {
		janet_panicf("odin-process-result expects 1 argument, got %d", argc)
		return janet_wrap_nil()
	}

	// Convert argv to slice to access elements
	args := ([^]Janet)(argv)[:argc]

	// Check that the argument is a number
	if janet_checktype(args[0], .NUMBER) == 0 {
		janet_panic("odin-process-result expects a numeric argument")
		return janet_wrap_nil()
	}

	// Get the result
	result := janet_unwrap_number(args[0])

	fmt.printf("[Odin] odin-process-result called with result=%.2f\n", result)

	// Store the result for later processing
	global_result_janet = result

	fmt.printf("[Odin] Final result stored: %.2f\n", global_result_janet)

	return janet_wrap_nil()
}

// Initialize Janet environment and expose Odin functions
init_janet :: proc() -> ^Janet_Table {
	// Initialize Janet
	janet_init()

	// Create core environment
	env := janet_core_env(0)
	if env == nil {
		fmt.println("[Odin] Error: cannot create Janet environment")
		return nil
	}

	// Expose our Odin functions to Janet
	janet_def(
		env,
		"odin-calculate",
		janet_wrap_cfunction(odin_calculate_c),
		"Calculate the sum of two numbers in Odin",
	)

	janet_def(
		env,
		"odin-process-result",
		janet_wrap_cfunction(odin_process_result_c),
		"Process a result received from Janet",
	)

	fmt.println("[Odin] Janet environment initialized with exposed functions")

	return env
}

// Execute a Janet script from a string
run_janet_string :: proc(env: ^Janet_Table, script: string) -> bool {
	cscript := cast(cstring)raw_data(script)

	fmt.printf("[Odin] Executing Janet script\n")

	out: Janet
	result := janet_dostring(env, cscript, "script", &out)
	if result != 0 {
		fmt.printf("[Odin] Error executing script: %d\n", result)
		return false
	}

	return true
}

// Get a variable from Janet environment
get_janet_variable :: proc(env: ^Janet_Table, name: string) -> (Janet, bool) {
	// Create a Janet symbol for the variable name
	cname := cast(cstring)raw_data(name)
	sym_janet := janet_wrap_string(cname)

	// Resolve the symbol in the environment
	value := janet_resolve(env, sym_janet)

	// Check if the variable exists (nil means not found)
	if janet_checktype(value, .NIL) != 0 {
		return value, false
	}

	return value, true
}

// Get a number from a Janet variable
get_janet_number :: proc(env: ^Janet_Table, name: string) -> (f64, bool) {
	value, found := get_janet_variable(env, name)
	if !found {
		return 0, false
	}

	if janet_checktype(value, .NUMBER) == 0 {
		return 0, false // Not a number
	}

	return janet_unwrap_number(value), true
}

// Get a string from a Janet variable
get_janet_string :: proc(env: ^Janet_Table, name: string) -> (string, bool) {
	value, found := get_janet_variable(env, name)
	if !found {
		return "", false
	}

	if janet_checktype(value, .STRING) == 0 {
		return "", false // Not a string
	}

	cstr := janet_unwrap_string(value)
	if cstr == nil {
		return "", false
	}

	return string(cstr), true
}

// Cleanup Janet environment
cleanup_janet :: proc() {
	janet_deinit()
	fmt.println("[Odin] Janet environment closed")
}

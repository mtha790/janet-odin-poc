(import spork/sh)
(import spork/argparse)

# Operating system detection
(def os-type (os/which))

# Default configuration
(def default-config
  (case os-type
    :linux {:lib "-ljanet" :path "/usr/local/lib"}
    :macos {:lib "-ljanet" :path "/opt/homebrew/lib:/usr/local/lib"}
    :windows {:lib "janet.lib" :path ""}
    (do
      (printf "Unsupported operating system: %s" os-type)
      (os/exit 1))))

# Parse command line arguments
(def argparse-params
  ["Build script for Odin-Janet integration"
   "lib" {:kind :option
          :short "l"
          :help "Library flag (e.g., -ljanet)"
          :default (default-config :lib)}
   "path" {:kind :option
           :short "p"
           :help "Library path (e.g., /usr/local/lib)"
           :default (default-config :path)}])

(def args (argparse/argparse ;argparse-params))
(if (args "help") (os/exit 0))

(def janet-config {:lib (args "lib") :path (args "path")})

# Build the odin command arguments
(def odin-args
  (if (= os-type :windows)
    ["odin" "build" "." "-out:odin-janet.exe" (string "-extra-linker-flags:" (janet-config :lib))]
    (if (not (empty? (janet-config :path)))
      ["odin" "build" "." "-out:odin-janet" (string "-extra-linker-flags:-L" (janet-config :path) " " (janet-config :lib))]
      ["odin" "build" "." "-out:odin-janet" (string "-extra-linker-flags:" (janet-config :lib))])))

# Execute the build command using spork/sh
(def result (sh/exec-slurp ;odin-args))

# Check compilation result
(if (= (result :exit-code) 0)
  (print "✅ Build successful")
  (do
    (print "❌ Build failed")
    (os/exit 1)))

# Odin-Janet Integration

Bidirectional integration between Odin and Janet where:
1. Odin exposes functions to Janet
2. Janet calls Odin functions and processes results
3. Janet returns processed results back to Odin

## Files

- `main.odin` - Main program
- `janet.odin` - Janet C API bindings and integration functions
- `script.janet` - Janet script demonstrating bidirectional interaction
- `build.janet` - Janet build script

## Prerequisites

- [Janet](https://janet-lang.org/) installed
- [Odin](https://odin-lang.org/) compiler

## Build & Run

```bash
# Build and run
janet build.janet
./odin-janet

# Custom library configuration
janet build.janet --lib -ljanet --path /custom/path
janet build.janet -l janet.lib -p "C:\custom\path"
```

## How it works

Odin exposes functions to Janet, Janet calls them and processes results, then returns data back to Odin.

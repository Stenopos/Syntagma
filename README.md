```
                        .=++=+:
                      :+++=*++=
                     .++-.:..
                   .+#*+==-::.
                 .+#*****++=-.
                :##***#**++==.
               :###*****+=-=+
              :#*##***+===+=.
              #***==+=+*#+:
             =#+*+=+%%*-:.
        ..  .#%@@%@#-....
       .-+**#@@@%*-.::..
          -*%%%*=-=+::.
        :**#-*+-=--*#*=:.
        .. :++-=-:  :*%*+.
           =*=-==.    -###*:
          :%#+@@+     -#%*+=
          -%@@@+      :**+*-
           .:.            .
```

# Stenopos

**Memory-safe. Taint-aware. Effect-typed.**

Stenopos is a systems programming language that treats security as a type system property. It combines Python-style readability with Rust-level safety, and adds security dimensions — taint tracking, effect types, constant-time types — that no other systems language builds in from the start.

---

## Why Stenopos?

Most security bugs fall into a handful of known categories. Stenopos prevents them at compile time:

| Attack class | Prevention |
|---|---|
| Buffer overflow, use-after-free | NOVA memory model — automatic, zero-cost deallocation |
| SQL / command / XSS injection | Taint tracking — tainted data cannot reach a sink without sanitization |
| Supply-chain side effects | Effect types — `@pure` functions cannot do I/O |
| Timing side-channels | `secret[T]` — constant-time operations enforced by the type system |
| Null pointer dereferences | `T?` nullable types — must be checked before use |

---

## Features

- **Python-style syntax** — colon-indent blocks, no braces, no semicolons
- **C-style declarations** — `int32 x = 42`, familiar to systems programmers
- **Mutable by default** — use `const` for immutability, not `let`/`mut` noise
- **NOVA memory safety** — automatic `free` at scope end, no GC, no manual memory management
- **Borrow checker** — prevents use-after-move at compile time
- **Taint tracking** — injection attacks caught at compile time (designed)
- **Effect types** — `@pure`, `@io`, `@network` annotations enforced by the compiler (designed)
- **Constant-time types** — `secret[T]` prevents timing leaks (designed)
- **Generics** — `func identity[T](T val) -> T`, `struct Pair[T, U]`, monomorphization
- **Traits** — `trait Printable:`, `impl Printable for Point:`, default implementations
- **Modules** — `module math.vector`, `import math.vector.Vec3`, grouped imports
- **Error handling** — `try/catch`, `with` resource blocks, `defer`, `?` operator
- **C FFI** — `extern "C"` for zero-overhead C interop
- **Inline assembly** — `asm:` blocks with GCC/LLVM constraints
- **Concurrency** — threads, channels, atomic types, RwLock
- **Testing** — `@test` attribute, `assert_eq`, fixtures, `stenopos test`
- **Single binary** — one tool: build, run, test, check, format

---

## Install

```bash
curl -fsSL https://stenopos.github.io/install.sh | sh
```

This installs the `stenopos` binary to `~/.local/bin/`. Add it to your PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Verify:

```bash
stenopos --version
```

---

## Quick start

```stenopos
func main() -> int32:
    str name = "world"
    printf("Hello, {name}!\n")
    return 0
```

```bash
stenopos run hello.sten
```

---

## A real example

```stenopos
// Fibonacci — iterative
func fib(int32 n) -> int32:
    if (n <= 1):
        return n
    int32 a = 0
    int32 b = 1
    for (i in 2..n):
        int32 c = a + b
        a = b
        b = c
    return b

func main() -> int32:
    for (i in 0..10):
        printf("fib({i}) = {fib(i)}\n")
    return 0
```

---

## The security model

```stenopos
// Input from the network is tainted
@tainted str user_input = request.get("name")

// The compiler refuses to let tainted data reach a SQL sink
// db.query("SELECT * FROM users WHERE name = '{user_input}'")   // compile error

// Sanitize it first
str safe = sql_escape(user_input)
db.query("SELECT * FROM users WHERE name = '{safe}'")           // ok

// Functions declare their effects
@pure func hash(str data) -> uint64:       // cannot do I/O
    // ...

@io @network func fetch(str url) -> str:  // must have both permissions
    // ...
```

---

## Documentation

- [stenopos.github.io](https://stenopos.github.io) — full documentation
- [Getting started](https://stenopos.github.io/getting-started/) — install + hello world
- [Language guide](https://stenopos.github.io/language-guide/overview/) — full language reference
- [Security model](https://stenopos.github.io/security/overview/) — taint, effects, constant-time types
- [Examples](https://github.com/Stenopos/examples) — working programs
- [Standard library](https://github.com/Stenopos/std) — built-in modules

---

## Releases

Stenopos releases follow [semantic versioning](https://semver.org/). Downloads are attached to each [GitHub Release](https://github.com/Stenopos/Syntagma/releases).

| Asset | Description |
|---|---|
| `stenopos-x86_64-linux.tar.gz` | Linux x86-64 binary |
| `stenopos-aarch64-linux.tar.gz` | Linux ARM64 binary |
| `stenopos-x86_64-macos.tar.gz` | macOS x86-64 binary |
| `stenopos-aarch64-macos.tar.gz` | macOS ARM64 (Apple Silicon) binary |

---

## License

Licensed under either of:

- [MIT License](LICENSE-MIT)
- [Apache License, Version 2.0](LICENSE-APACHE)

at your option.

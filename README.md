<p align="center"><img src="assets/full-banner.png" alt="Stenopos" width="600"></p>

# Stenopos

**Memory-safe. Taint-aware. Effect-typed.**

Stenopos is a systems programming language that treats security as a type system property. It combines C-style familiarity with Rust-level safety, and adds security dimensions — taint tracking, effect types, constant-time types — that no other systems language builds in from the start.

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

- **Brace-based syntax** — C-style `{ }` blocks, no semicolons, newlines as terminators
- **C-style declarations** — `int32 x = 42`, familiar to systems programmers
- **Mutable by default** — use `const` for immutability, not `let`/`mut` noise
- **NOVA memory safety** — automatic `free` at scope end, no GC, no manual memory management
- **Borrow checker** — prevents use-after-move at compile time
- **Taint tracking** — injection attacks caught at compile time (designed)
- **Effect types** — `@pure`, `@io`, `@network` annotations enforced by the compiler (designed)
- **Constant-time types** — `secret[T]` prevents timing leaks (designed)
- **Generics** — `func identity[T](T val) -> T`, monomorphization
- **Traits** — `trait Printable { }`, `impl Printable for Point { }`, default implementations
- **Modules** — `import std.collections.HashMap`, grouped imports
- **Error handling** — `try/catch/finally`, `defer`, resource management
- **C FFI** — `extern "C"` for zero-overhead C interop
- **Inline assembly** — `asm { }` blocks with GCC/LLVM constraints
- **Concurrency** — `spawn`, `chan`, `atomic`, `mutex`, `rwlock`, `spinlock`, `semaphore`
- **Testing** — `@test` attribute, `assert_eq`, `stenopos test`
- **Single binary** — one tool: build, run, test, check, format

---

## Quick start

```stenopos
func main() -> int32 {
    println("Hello, Stenopos!")
    return 0
}
```

```bash
stenopos run hello.sten
```

---

## A real example

```stenopos
// Fibonacci — iterative
func fib(int32 n) -> int32 {
    if (n <= 1) {
        return n
    }
    int32 a = 0
    int32 b = 1
    for (i in 2..n) {
        int32 c = a + b
        a = b
        b = c
    }
    return b
}

func main() -> int32 {
    for (i in 0..10) {
        println("fib(%d) = %d", i, fib(i))
    }
    return 0
}
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
@pure func hash(str data) -> uint64 {       // cannot do I/O
    // ...
}

@io @network func fetch(str url) -> str {   // must have both permissions
    // ...
}
```

---

## Documentation

- [stenopos.github.io](https://stenopos.github.io) — full documentation
- [Examples](https://github.com/Stenopos/examples) — working programs
- [Standard library](https://github.com/Stenopos/std) — built-in modules

---

## Releases

Stenopos releases follow [semantic versioning](https://semver.org/). Downloads are attached to each [GitHub Release](https://github.com/Stenopos/Syntagma/releases).

| Asset | Description |
|---|---|
| `stenopos-linux-x86_64` | Linux x86-64 binary |
| `stenopos-linux-aarch64` | Linux ARM64 binary |

---

## Building from source

Stenopos requires Rust, LLVM (`llc`), and a C compiler (`cc`).

> **Note:** The compiler source is hosted privately. This repository contains release binaries and project documentation. See the [releases page](https://github.com/Stenopos/Syntagma/releases) for downloads.

---

## License

Licensed under either of:

- [MIT License](LICENSE-MIT)
- [Apache License, Version 2.0](LICENSE-APACHE)

at your option.

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
| Integer overflow → undersized buffers | Checked arithmetic — `+`/`-`/`*` trap on overflow instead of wrapping |

---

## Features

- **Brace-based syntax** — C-style `{ }` blocks, no semicolons, newlines as terminators
- **C-style declarations** — `int32 x = 42`, familiar to systems programmers
- **Mutable by default** — use `const` for immutability, not `let`/`mut` noise
- **NOVA memory safety** — automatic `free` at scope end, no GC, no manual memory management
- **Borrow checker** — prevents use-after-move at compile time
- **Checked integer overflow** — `+`/`-`/`*` trap on overflow instead of wrapping silently; `wrapping_add`/`wrapping_sub`/`wrapping_mul` opt into modular arithmetic
- **Taint tracking** — injection attacks caught at compile time (designed)
- **Effect types** — `@pure`, `@io`, `@network` annotations enforced by the compiler (designed)
- **Constant-time types** — `secret[T]` prevents timing leaks (designed)
- **Generics** — `func identity[T](T val) -> T`, monomorphization
- **Traits** — `trait Printable { }`, `impl Printable for Point { }`, default implementations
- **Modules** — `import std.collections.HashMap`, grouped imports, `pub`/private visibility enforced across modules
- **Error handling** — `try/catch/finally`, block-scoped `defer`, resource management
- **Contracts** — `@requires`/`@ensures` pre/postconditions checked at runtime
- **Built-in tooling** — `stenopos fmt`, `lint`, `doc`, and `test` in the one binary
- **C FFI** — `extern "C"` for zero-overhead C interop
- **Inline assembly** — `asm { }` blocks with GCC/LLVM constraints
- **Concurrency** — `spawn`, `chan`, `atomic`, `mutex`, `rwlock`, `spinlock`, `semaphore`
- **Testing** — `@test` attribute, `assert_eq`, `stenopos test`
- **Cross-compilation** — `stenopos build --target aarch64` builds for **11 CPU architectures** in one command (x86_64, ARM 32/64, RISC-V, PowerPC 32/64, MIPS BE/LE, s390x) — every word size and byte order
- **Build profiles** — `stenopos.toml` profiles: `stenopos build` is a fast, debuggable `draft`; `stenopos build --release` is optimized, stripped, and anonymized (reads as a generic C binary)
- **Single binary** — one tool: build, run, test, check, format

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Stenopos/Syntagma/main/install.sh | sh
```

The installer detects your OS/architecture, downloads the matching binary from
the latest [GitHub Release](https://github.com/Stenopos/Syntagma/releases),
**verifies its SHA-256 checksum** (and GPG signature when present), and installs
`stenopos`. Pin a version with `STENOPOS_VERSION=v1.0.0-beta.11`, or change the
target dir with `STENOPOS_INSTALL=$HOME/.local/bin`.

Prefer to do it by hand? Download `stenopos-linux-<arch>` and `SHA256SUMS` from a
release, run `sha256sum -c SHA256SUMS`, then move the binary onto your `PATH`.

Stenopos needs `llc` (LLVM 14 or newer) and `cc` (a C compiler) at compile time:
`sudo apt-get install -y llvm clang` (Debian/Ubuntu) or `brew install llvm` (macOS).

Every published release is proven against a suite of real programs — see the
[example verification runs](https://github.com/Stenopos/examples/actions/workflows/verify.yml)
([![Verify examples](https://github.com/Stenopos/examples/actions/workflows/verify.yml/badge.svg)](https://github.com/Stenopos/examples/actions/workflows/verify.yml)).

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

Each release also ships a `SHA256SUMS` file (and, when signing is enabled, a
`SHA256SUMS.asc` GPG signature) so you can verify what you downloaded.

| Asset | Description |
|---|---|
| `stenopos-linux-x86_64` | Linux x86-64 binary |
| `stenopos-linux-aarch64` | Linux ARM64 binary (also runs on Raspberry Pi 3/4/5) |
| `stenopos-linux-ppc64le` | Linux 64-bit PowerPC (little-endian) binary |
| `stenopos-linux-riscv64` | Linux 64-bit RISC-V binary |
| `stenopos-linux-armv7` | Linux 32-bit ARM (hard-float) binary |
| `stenopos-linux-s390x` | Linux 64-bit IBM Z (big-endian) binary |
| `SHA256SUMS` | SHA-256 checksums for the binaries |
| `SHA256SUMS.asc` | Detached GPG signature of `SHA256SUMS` (when available) |

Any of these can additionally **cross-compile** your programs to eleven CPU
architectures via `stenopos build --target <arch>`.

---

## How this project is organized

Stenopos is developed privately and distributed publicly. What you see on GitHub
is everything you need to *use* the language:

| Repository | Contents |
|---|---|
| [`stenopos`](https://github.com/Stenopos/Syntagma) (this repo) | Release binaries, the installer, project README |
| [`examples`](https://github.com/Stenopos/examples) | Example programs + a workflow that verifies every release |
| [`std`](https://github.com/Stenopos/std) | Standard library |
| [stenopos.github.io](https://stenopos.github.io) | Documentation |

The **compiler source is hosted privately** and is not part of this repository —
its `Code` tab is intentionally limited to the installer and docs. **Stenopos is
self-hosted:** the compiler is written entirely in Stenopos and builds itself, with
no Rust or other language involved (the transitional Rust bootstrap was removed in
`v1.0.0-rc.1` — see [the announcement](https://stenopos.github.io/blog/)).
Every release is built by CI, checksummed, and verified against the public example
suite before it ships.

## License

The published **binaries, installer, examples, and documentation** are licensed
under either of:

- [MIT License](LICENSE-MIT)
- [Apache License, Version 2.0](LICENSE-APACHE)

at your option. (This license covers the distributed artifacts in these public
repositories; the private compiler source is not distributed under these terms.)

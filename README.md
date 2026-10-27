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
- **Taint tracking** — injection attacks caught at compile time: a `@tainted` value cannot reach a `@sink` without passing through a `@sanitizer`
- **Effect types** — `@pure`, `@io`, `@net` annotations enforced by the compiler; a `@pure` function cannot perform I/O
- **Constant-time types** — `secret[T]` values are operated on in constant time, preventing timing side-channels
- **Generics** — `func identity[T](T val) -> T`, monomorphization
- **Traits** — `trait Printable { }`, `impl Printable for Point { }`, default implementations
- **Modules** — `import std.collections.HashMap`, grouped imports, `pub`/private visibility enforced across modules
- **Error handling** — `try/catch/finally`, block-scoped `defer`, resource management
- **Contracts** — `@requires`/`@ensures` pre/postconditions checked at runtime
- **`tagma`, the build tool** — `tagma new`, `build`, `run`, `test`, `check`, `fmt`, `lint`, `doc` for projects with a `Tagma.toml`; the compiler, `stenopos`, still builds single files
- **C FFI** — `extern "C"` for zero-overhead C interop
- **Inline assembly** — `asm { }` blocks with GCC/LLVM constraints
- **Concurrency** — `spawn`, `chan`, `atomic`, `mutex`, `rwlock`, `spinlock`, `semaphore`
- **Green-thread scheduler** — `spawn` runs cooperative M:N green threads (stackful fibers on a per-CPU worker pool); thousands of channel-blocked Hemerodromes ride on a handful of OS threads
- **Heap-owning channels & locks** — move `str`, structs, `List`, and `HashMap` across `chan[T]` and hold them in `mutex`/`rwlock`, with zero-copy in-place borrows
- **Language server** — `stenopos lsp` brings live diagnostics, hover, go-to-definition, and completion to any LSP editor
- **Testing** — `@test` attribute, `assert_eq`, `tagma test`
- **Cross-compilation** — `stenopos build --target aarch64` builds for **11 CPU architectures** in one command (x86_64, ARM 32/64, RISC-V, PowerPC 32/64, MIPS BE/LE, s390x) — every word size and byte order
- **Build profiles** — `tagma build` is a fast, debuggable `draft`; `tagma build --release` is optimized, stripped, and anonymized (reads as a generic C binary)
- **Editions** — the language evolves through editions (`edition = "2026"`), so a new compiler never breaks an existing project

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Stenopos/Syntagma/main/install.sh | sh
```

The installer detects your OS/architecture, downloads the matching binary from
the newest [GitHub Release](https://github.com/Stenopos/Syntagma/releases),
**verifies the release signature** against the pinned Stenopos release key and
the bundle's **SHA-256 checksum**, and installs Syntagma: the `tagma` build
tool, the `stenopos` compiler, the runtime and the standard library. Pin a version with `STENOPOS_VERSION=v1.0.0-rc.5`, or change the
target dir with `STENOPOS_INSTALL=$HOME/.local/bin`.

Prefer to do it by hand? See [Verify a download](#verify-a-download).

Stenopos needs `llc` (LLVM 14 or newer) and `cc` (a C compiler) at compile time:
`sudo apt-get install -y llvm clang` (Debian/Ubuntu) or `brew install llvm` (macOS).

## Quick start

```bash
tagma new hello
cd hello
tagma run          # Hello from hello!
```

`tagma new` writes a `Tagma.toml` and `src/main.sten`:

```toml
[package]
name = "hello"
version = "0.1.0"
edition = "2026"

[dependencies]
util = { path = "../util" }   # local path dependencies; the package registry is coming
```

For a single file there is no project needed:

```stenopos
func main() -> int32 {
    println("Hello, Stenopos!")
    return 0
}
```

```bash
stenopos run hello.sten
```

### Syntagma, tagma and stenopos

| Name | What it is |
|---|---|
| **Syntagma** | The toolchain: what you install and what each release ships |
| **`tagma`** | The build tool you use day to day, for projects |
| **`stenopos`** | The compiler (also the language server); builds single files |

All three share one version.

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
        println("fib({i}) = {fib(i)}")
    }
    return 0
}
```

---

## The security model

```stenopos
// A function returning untrusted input marks its result @tainted
@tainted func user_input() -> str {
    return request.get("name")
}

// A @sink refuses tainted data — enforced at compile time
@sink func db_query(str sql) -> void { /* ... */ }

func main() -> void {
    str q = "SELECT * FROM users WHERE name = '" + user_input() + "'"
    db_query(q)                          // compile error: tainted value passed to @sink
    db_query(sql_escape(user_input()))   // ok — sanitized first
}

// Functions declare their effects; a @pure function cannot do I/O
@pure func hash(str data) -> uint64 {
    // ...
}

@io @net func fetch(str url) -> str {    // must declare its effects
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

Every file in a release is signed: each asset has a detached `.asc` signature,
and `SHA256SUMS` lists every asset's checksum and is itself signed.

| Asset | Description |
|---|---|
| `syntagma-<version>-linux-<arch>.tar.gz` | The toolchain bundle (`tagma`, `stenopos`, runtime, std) for each architecture below; what the installer installs |
| `tagma-linux-<arch>` | The build tool on its own |
| `stenopos-linux-x86_64` | Linux x86-64 binary |
| `stenopos-linux-aarch64` | Linux ARM64 binary (also runs on Raspberry Pi 3/4/5) |
| `stenopos-linux-ppc64le` | Linux 64-bit PowerPC (little-endian) binary |
| `stenopos-linux-riscv64` | Linux 64-bit RISC-V binary |
| `stenopos-linux-armv7` | Linux 32-bit ARM (hard-float) binary |
| `stenopos-linux-s390x` | Linux 64-bit IBM Z (big-endian) binary |
| `SHA256SUMS` | SHA-256 checksums for the binaries |
| `SHA256SUMS.asc` | Signature of `SHA256SUMS` |
| `<asset>.asc` | Signature of each individual asset |

Any of these can additionally **cross-compile** your programs to eleven CPU
architectures via `stenopos build --target <arch>`.

### Verify a download

Releases are signed by the **Stenopos Release Signing** key:

```
21CB C7C3 F66D FAFD D038  5515 E5FB D284 8395 1BCB
```

The public key is [`stenopos-signing-key.asc`](stenopos-signing-key.asc) in this
repository and on [keys.openpgp.org](https://keys.openpgp.org/search?q=21CBC7C3F66DFAFDD0385515E5FBD28483951BCB).

```bash
gpg --import stenopos-signing-key.asc          # or: gpg --recv-keys 21CBC7C3F66DFAFDD0385515E5FBD28483951BCB
gpg --verify SHA256SUMS.asc SHA256SUMS         # must report the fingerprint above
sha256sum -c --ignore-missing SHA256SUMS       # checks the files you downloaded
```

---

## How this project is organized

Stenopos is developed privately and distributed publicly. What you see on GitHub
is everything you need to *use* the language:

| Repository | Contents |
|---|---|
| [`Syntagma`](https://github.com/Stenopos/Syntagma) (this repo) | Release binaries, the installer, the release key, project README |
| [`examples`](https://github.com/Stenopos/examples) | Example programs |
| [`std`](https://github.com/Stenopos/std) | Standard library |
| [stenopos.github.io](https://stenopos.github.io) | Documentation |

The **compiler source is hosted privately** and is not part of this repository —
its `Code` tab is intentionally limited to the installer and docs. **Stenopos is
self-hosted:** the compiler is written entirely in Stenopos and builds itself, with
no Rust or other language involved (the transitional Rust bootstrap was removed in
`v1.0.0-rc.1` — see [the announcement](https://stenopos.github.io/project/changelog/syntagma/stenopos-compiles-itself-and-the-rust-is-gone/)).
Every release is built by CI, checksummed, and verified against the public example
suite before it ships.

## License

The published **binaries, installer, examples, and documentation** are licensed
under either of:

- [MIT License](LICENSE-MIT)
- [Apache License, Version 2.0](LICENSE-APACHE)

at your option. (This license covers the distributed artifacts in these public
repositories; the private compiler source is not distributed under these terms.)

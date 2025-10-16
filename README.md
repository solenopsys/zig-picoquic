# zig-picoquic

Zig wrapper and build system for [picoquic](https://github.com/privateoctopus/picoquic), a minimalist QUIC implementation. This project follows the structure of `zig-lmdbx`: all C sources are stored in `libs/picoquic`, and `build.zig` compiles them into a shared library.

## Overview

This wrapper provides:
- **Zig bindings** for picoquic C library
- **Build system** using `zig build` (no CMake required)
- **Echo example** demonstrating QUIC client/server communication
- **picotls integration** - picoquic's TLS 1.3 library for QUIC is automatically included

The project compiles picoquic and its dependency picotls into a single dynamic library and provides a simple Zig API wrapper.

## Project Structure

- `libs/picoquic` – Clone of the [picoquic](https://github.com/privateoctopus/picoquic) repository
  - `libs/picoquic/picotls` – TLS 1.3 library (picoquic submodule dependency)
- `src/lib.zig` – Zig wrapper that imports picoquic C headers
- `src/main.zig` – Echo server/client example application
- `build.zig` – Build script that compiles picoquic, picotls, and the Zig wrapper

## Quick Start

1. Clone picoquic sources into `libs/picoquic` (including picotls submodule):
   ```sh
   git clone https://github.com/privateoctopus/picoquic libs/picoquic
   cd libs/picoquic
   git submodule update --init --recursive
   cd ../..
   ```

2. Build the library and examples:
   ```sh
   zig build
   ```

   This produces:
   - `zig-out/lib/libpicoquic.so` – Shared library containing picoquic + picotls
   - `zig-out/bin/picoquic_echo` – Echo example (client/server)
   - `zig-out/bin/picoquicdemo` – Original picoquic demo
   - `zig-out/bin/picoquic_sample` – Original picoquic sample

## Echo Example

The echo example demonstrates a simple QUIC client/server that echoes messages back.

### Running the Server

```sh
./zig-out/bin/picoquic_echo server 4443
```

This starts an echo server on port 4443 using the test certificates from `libs/picoquic/certs/`.

### Running the Client

```sh
./zig-out/bin/picoquic_echo client localhost 4443 "Hello QUIC!"
```

Expected output:
```
info: Connecting to localhost:4443
info: Server replied: "Hello QUIC!"
```

### Custom Certificates

You can specify custom certificates for the server:

```sh
./zig-out/bin/picoquic_echo server 4443 /path/to/cert.pem /path/to/key.pem
```

## Usage

```
picoquic_echo server <port> [cert_path key_path]
picoquic_echo client <host> <port> <message>

Defaults use the test certificates shipped with picoquic.
```

## Build Configuration

The `build.zig` script compiles:

1. **picoquic** – Core QUIC implementation (from `libs/picoquic/picoquic/*.c`)
2. **picohttp** – HTTP/3 support (from `libs/picoquic/picohttp/*.c`)
3. **loglib** – Logging utilities (from `libs/picoquic/loglib/*.c`)
4. **picotls** – TLS 1.3 library (from `libs/picotls/lib/*.c`)
5. **minicrypto** – Cryptographic backend (from `libs/picotls/deps/{cifra,micro-ecc}/*.c`)

All sources are compiled with:
- C11 standard
- OpenSSL backend (`-DPICOTLS_USE_OPENSSL`)
- BBR congestion control enabled

## Modifying Source Sets

To include additional C files or exclude unnecessary ones, modify the source arrays in `build.zig`:
- `picoquic_sources`
- `picohttp_sources`
- `loglib_sources`
- `picotls_core_sources`
- `picotls_minicrypto_sources`

## Requirements

- **Zig** ≥ 0.15.0
- **OpenSSL** (`libssl-dev`, `libcrypto-dev`)
- **System libraries**: `pthread`, `m` (math), `dl` (Linux)

On Debian/Ubuntu:
```sh
sudo apt install libssl-dev
```

On Fedora:
```sh
sudo dnf install openssl-devel
```

## Using as a Zig Package

`build.zig` registers a `picoquic` module, so other Zig packages can add this as a dependency and import:

```zig
const pico = @import("picoquic");

// Access picoquic C API
const quic = pico.c.picoquic_create(...);

// Or use the Zig wrapper functions
try pico.startEchoServer(allocator, 4443, "cert.pem", "key.pem");
const response = try pico.runEchoClient(allocator, "localhost", 4443, "Hello!");
```

## Implementation Notes

### picotls Integration

picotls is picoquic's TLS 1.3 implementation, automatically included as a Git submodule. The build system:
1. Compiles picotls core library (`lib/picotls.c`, `lib/hpke.c`, etc.)
2. Includes minicrypto backend (Cifra + micro-ecc) for standalone operation
3. Links against OpenSSL for performance-critical operations
4. All picotls headers are available via `@cImport` in `src/lib.zig`

### Memory Management

The Zig wrapper uses manual memory management with allocators:
- Server callbacks receive allocator in context
- Client state manages response buffer with fixed 4KB size
- Applications must call `allocator.free()` on returned data

### Callback Architecture

Both server and client use C callbacks:
- `serverStreamCallback` – Echoes received data back to client
- `clientStreamCallback` – Collects server response
- `serverLoopCallback` / `clientLoopCallback` – Manage packet loop lifecycle

## License

This wrapper follows picoquic's license (MIT). See `libs/picoquic/LICENSE` for details.

## References

- [picoquic](https://github.com/privateoctopus/picoquic) – Minimalist QUIC implementation
- [picotls](https://github.com/h2o/picotls) – TLS 1.3 library
- [QUIC Protocol](https://www.rfc-editor.org/rfc/rfc9000.html) – RFC 9000

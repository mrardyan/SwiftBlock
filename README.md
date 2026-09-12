<p align="center">
  <img src="Docs/Assets/SwiftBlock.svg" width="120" height="120" alt="SwiftBlock Logo">
  <h1 align="center">SwiftBlock</h1>
  <p align="center">
    <strong>Stop rewriting the same code. Start snapping blocks.</strong>
  </p>
  <p align="center">
    <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.10-orange.svg?style=flat-square" alt="Swift 5.10"></a>
    <a href="https://developer.apple.com"><img src="https://img.shields.io/badge/Platform-macOS%2012.0%2B-blue.svg?style=flat-square" alt="Platform macOS"></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg?style=flat-square" alt="License MIT"></a>
  </p>
</p>

---

**SwiftBlock** turns production-ready architecture into modular building blocks for Swift. Skip hours of tedious setup and snap complete feature layers, network engines, auto-wired dependencies, and unit tests directly into your iOS, macOS, and Vapor codebases in seconds.

---

## Key Capabilities

- **Modular Brick Engine**: Attach production-ready infrastructure, feature, and utility components (`Network`, `Scene`, `Storage`) in seconds.
- **Instant Project Baseplates**: Lay down complete SwiftUI or Vapor project baseplates ready for immediate development.
- **Automatic Integration**: Auto-registers dependencies in `DependencyContainer.swift` and routes in `AppCoordinator.swift` without manual boilerplate editing.
- **Composition Kits**: Generate complete architectural layers in a single command using pre-configured feature blueprints (`clean-feature`).
- **Team Box Registries**: Publish, fetch, and share team component blocks across monorepos via Git repositories (`swiftblock box`).
- **Interactive Wizard Mode**: Guided terminal prompt engine when arguments are omitted.
- **Automated Unit Tests**: Automatically transforms single-source brick test definitions into **Swift Testing** or **XCTest**.
- **Simulation Mode (`--dry-run`)**: Test component generation and code injections without writing to disk.

---

## Quick Start

### 1. Installation

#### Via Homebrew (Recommended)

```bash
brew install mrardyan/tap/swiftblock
```

#### Via Makefile (From Source)

```bash
git clone https://github.com/mrardyan/swiftblock.git
cd swiftblock
make install
```

---

### 2. Basic Workflow

#### Step 1: Initialize a SwiftUI Project Baseplate

```bash
swiftblock baseplate MyApp --bundle-prefix com.mycompany
cd MyApp && make setup && make generate
```

#### Step 2: Snap Infrastructure Bricks

```bash
swiftblock snap network
swiftblock snap auth
swiftblock snap securestorage
```

#### Step 3: Snap a Feature Blueprint (Clean Architecture Module)

```bash
swiftblock kit run clean-feature Profile
```

---

## Documentation Index

Explore the complete SwiftBlock documentation guides:

| Guide                                                              | Description                                                                                    |
| ------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------- |
| 🚀 [**Getting Started**](Docs/01-Getting-Started.md)               | Step-by-step tutorial on initializing baseplates and snapping components.                      |
| 🧩 [**Core Concepts**](Docs/02-Core-Concepts.md)                   | Architecture breakdown, automatic dependency registration, and Stencil variable engine.        |
| 🏗️ [**Baseplates Guide**](Docs/03-Baseplates-Guide.md)             | Deep dive on Baseplate starters (`SwiftUI`/`Vapor`), Tuist/XcodeGen manifests, and guardrails. |
| 📚 [**Bricks Catalog**](Docs/04-Bricks-Catalog.md)                 | Comprehensive catalog of all 28 built-in Core, Feature, and Utility components.                |
| 📦 [**Custom Bricks & Boxes**](Docs/05-Custom-Bricks-and-Boxes.md) | Guide to writing `brick.yml` manifests, local overrides, and team Box registries.              |
| 📐 [**Composition Kits**](Docs/06-Composition-Kits.md)             | Multi-brick architectural blueprints (`clean-feature`).                                        |
| 📖 [**CLI Reference**](Docs/07-CLI-Reference.md)                   | Exhaustive CLI flags and subcommands reference.                                                |

---

## Local Development & Testing

```bash
# Build release binary locally
make build

# Run Swift Testing unit test suite
make test

# Run End-to-End integration test matrix
make test-e2e

# Install binary & assets locally to /usr/local/bin
make install
```

---

## License

Distributed under the MIT License.

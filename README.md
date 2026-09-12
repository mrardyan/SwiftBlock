<p align="center">
  <img src="Docs/Assets/SwiftBlock.svg" width="120" height="120" alt="SwiftBlock Logo">
  <h1 align="center">SwiftBlock</h1>
  <p align="center">
    <strong>Swift building blocks to create anything. Inspired by Lego.</strong>
  </p>
  <p align="center">
    <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.10-orange.svg?style=flat-square" alt="Swift 5.10"></a>
    <a href="https://developer.apple.com"><img src="https://img.shields.io/badge/Platform-macOS%2012.0%2B-blue.svg?style=flat-square" alt="Platform macOS"></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg?style=flat-square" alt="License MIT"></a>
  </p>
</p>

---

**SwiftBlock** is a modular scaffolding engine and code component marketplace designed specifically for modern Swift and Apple engineering. Inspired by the satisfying simplicity of Lego building blocks, SwiftBlock empowers iOS developers and enterprise teams to snap pre-configured, production-grade architecture components directly into their codebases.

---

## Key Features

- **Lego-Inspired CLI Surface**: Unified CLI commands (`baseplate`, `snap`, `kit`, `box`, `doctor`).
- **Instant Project Baseplates**: Lay down complete SwiftUI baseplates powered by **Tuist** or **XcodeGen**.
- **Singleton & Generative Bricks**:
  - **Singletons**: Installed once per project (`network`, `storage`, `logger`, `config`, `auth`, `analytics`, `featureflag`).
  - **Generatives**: Multi-instance feature components (`scene`, `usecase`, `repository`, `service`, `entity`, `coordinator`, `component`, `mapper`, `validator`).
- **Smart Stencil Variable Engine**: Prompt for custom variables interactively or pass key-values via CLI (`--var key=val` or `-v key=val`).
- **Smart Code Injector**: Automatically inject routing code into `AppCoordinator.swift` or dependency registrations into `DependencyContainer.swift`.
- **Lifecycle Hooks System**: Execute `pre_snap` and `post_snap` lifecycle scripts (e.g., `make generate`, `tuist generate`).
- **Remote Box Registries & Monorepos**: Fetch, cache, and snap bricks directly from Git URLs or private team Box repositories.
- **Interactive WizardKit Mode**: Guided TUI prompt engine when arguments are omitted.
- **Project Configuration (`.swiftblock/config.yml`)**: Clean YAML configuration for bundle prefixes, build tools, and directory path mappings.
- **Automated Composable Unit Tests**: Every snapped brick includes composable unit tests.
- **Simulation Mode (`--dry-run`)**: Test brick snapping without mutating disk state.

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

### 2. Usage

#### Project Baseplate Initialization

```bash
# Lay down a new Tuist-based SwiftUI project baseplate
swiftblock baseplate MyApp --bundle-prefix com.mycompany

# Create an XcodeGen-based project
swiftblock baseplate MyApp --tool xcodegen

# Dry-run simulation mode
swiftblock baseplate MyApp --dry-run

cd MyApp
make setup      # Install dependencies, git hooks & generate workspace
make generate   # Regenerate Xcode workspace manifest
```

#### Snapping Bricks (Attach Components)

```bash
# Snap Singleton Foundation Bricks
swiftblock snap network
swiftblock snap storage
swiftblock snap auth

# Snap Generative Architectural Bricks
swiftblock snap scene Home
swiftblock snap usecase Authenticate
swiftblock snap repository User
swiftblock snap service Payment

# Pass custom Stencil prompt variables
swiftblock snap network --var timeoutInterval=60

# Snap direct from Git URL (Single brick or Monorepo auto-discovery)
swiftblock snap https://github.com/mrardyan/swiftui-toast-brick.git Toast
```

#### Composition Kits & Box Registries

```bash
# Run a composition kit (batch generate Scene, UseCase, Repository, Service)
swiftblock kit run clean-feature Profile

# Manage team Box registries
swiftblock box add company https://github.com/company/ios-bricks.git
swiftblock box list
```

---

## Technical Terminology (The Lego Metaphor)

| Term            | Metaphor                  | Description                                                                                    |
| :-------------- | :------------------------ | :--------------------------------------------------------------------------------------------- |
| **`Baseplate`** | Project Starter           | Foundational project layout (`swiftblock baseplate MyApp`). Alias: `init`, `new`.              |
| **`Brick`**     | Code Template Unit        | Individual building block template (`network`, `scene`, `usecase`).                            |
| **`snap`**      | Attach / Inject Command   | Primary CLI verb to attach a brick (`swiftblock snap network`). Alias: `add`, `use`.           |
| **`Kit`**       | Composition Recipe        | Composes multiple bricks into a single command (`swiftblock kit run clean-feature`).           |
| **`Box`**       | Remote Registry           | Git repository containing a collection of bricks published by a team or community.             |
| **`WizardKit`** | Interactive Prompt Engine | Guided TUI prompt engine for interactive user configuration.                                   |

---

## Command Reference

| Command                               | Description                                                                 | Default                                          |
| :------------------------------------ | :-------------------------------------------------------------------------- | :----------------------------------------------- |
| `swiftblock baseplate <Name>`         | Lay down a new SwiftUI project baseplate (aliases: `init`, `new`)           | `Tuist` / `com.company`                          |
| `swiftblock snap <brick> [Name]`      | Snap local or remote brick into current project (aliases: `add`, `use`)     | `App/Sources/Features/` or `App/Sources/Core/`   |
| `swiftblock kit run <kit-name> [Name]`| Execute a multi-brick composition recipe                                    | `.swiftblock/kits/`                              |
| `swiftblock box add <name> <git-url>` | Register a remote team brick repository (tap)                               | `~/.swiftblock/store/v1/boxes/`                 |
| `swiftblock box list`                 | List all available local, remote, and box bricks                            |                                                  |
| `swiftblock doctor`                   | Diagnostic suite for environment and configuration validation              |                                                  |

---

## Project Configuration (`.swiftblock/config.yml`)

Every project includes a YAML configuration file stored inside `.swiftblock/config.yml`:

```yaml
projectName: MyApp
bundlePrefix: com.mycompany
generatorTool: tuist # Options: tuist | xcodegen

paths:
  scene: App/Sources/Features
  usecase: App/Sources/Features
  repository: App/Sources/Features
  network: App/Sources/Core/Network

kits:
  feature:
    - scene
    - usecase
    - repository
    - service
```

---

## Brick Specification Manifest (`brick.yml`)

Located inside brick directories (e.g., `Bricks/Singletons/Network/brick.yml`):

```yaml
name: network
category: infrastructure
instantiation: singleton
description: "Unified HTTP Transport Engine using URLSession and Swift Concurrency"
version: "1.0.0"
defaultPath: "App/Sources/Core/Network"

variables:
  - name: timeoutInterval
    type: string
    prompt: "Default request timeout in seconds?"
    default: "30"

injections:
  - target: "App/Sources/Core/DependencyContainer.swift"
    marker: "// MARK: - Register Services"
    content: "        container.register({{moduleName}}Service.self) { _ in {{moduleName}}Service() }"

hooks:
  post_snap:
    - "make generate"
```

---

## Local Development & Testing

```bash
# Build release binary locally
swift build -c release

# Run unit test suite (Swift Testing framework - 82 tests)
swift test

# Run End-to-End integration test matrix (13 scenarios)
./Scripts/test_e2e.sh
```

---

## License

Distributed under the MIT License.

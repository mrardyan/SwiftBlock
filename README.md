<p align="center">
  <img src="Docs/Assets/SwiftBlock.svg" width="120" height="120" alt="SwiftBlock Logo">
  <h1 align="center">SwiftBlock</h1>
  <p align="center">
    <strong>Swift building blocks to create anything.</strong>
  </p>
  <p align="center">
    <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.10-orange.svg?style=flat-square" alt="Swift 5.10"></a>
    <a href="https://developer.apple.com"><img src="https://img.shields.io/badge/Platform-macOS%2012.0%2B-blue.svg?style=flat-square" alt="Platform macOS"></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg?style=flat-square" alt="License MIT"></a>
  </p>
</p>

---

**SwiftBlock** is a modular framework providing composable Swift building blocks to create complete SwiftUI Xcode projects and tailored architecture foundations pre-configured with industry-standard developer tooling.

---

## Key Features

- **Instant Project Scaffolding**: Generate complete SwiftUI Xcode projects powered by **Tuist** or **XcodeGen**.
- **Interactive Wizard Mode**: Step-by-step CLI prompts when arguments are omitted for guided setup.
- **Core Foundation Blocks**: Modular infrastructure blocks (`storage`, `network`, `logger`, `config`, `auth`, `analytics`, `featureflag`).
- **Feature Architecture Blocks**: Scaffolds clean code components (`scene`, `usecase`, `repository`, `service`, `entity`, `coordinator`, `component`, `mapper`, `validator`).
- **Automated Unit Test Generation**: Automatically generates composable unit tests alongside every Core and Feature module.
- **Custom Architecture Kits**: Compose multi-brick templates into reusable kits (`swiftblock kit`).
- **CI/CD Pipeline Generator**: Automatic setup for Xcode Cloud, GitHub Actions, or GitLab CI.
- **Pre-configured Code Quality**: Built-in setup for SwiftLint, SwiftFormat, and pre-commit hooks.
- **Simulation Mode (`--dry-run`)**: Test project and module generation without mutating disk state.

---

## Quick Start

### 1. Installation

#### Via Homebrew (Recommended)

```bash
brew install mrardyan/tap/swiftblock
```

#### Via Shell Script

```bash
git clone https://github.com/mrardyan/swiftblock.git
cd swiftblock
chmod +x Scripts/install.sh
./Scripts/install.sh
```

---

### 2. Usage

#### Interactive Wizard Mode

Run commands without arguments to launch the interactive step-by-step wizard:

```bash
# Interactive project creation wizard
swiftblock new

# Interactive architecture module wizard
swiftblock add

# Interactive core block wizard
swiftblock core
```

#### Command Line Initialization

```bash
# Create a Tuist-based project (default)
swiftblock new MyApp --bundle-prefix com.mycompany

# Create an XcodeGen-based project
swiftblock new MyApp --tool xcodegen --bundle-prefix com.mycompany

# Dry-run simulation mode
swiftblock new MyApp --dry-run

cd MyApp
make setup      # Install dependencies, hooks & generate workspace
make generate   # Regenerate Xcode workspace manifest
```

#### Add Architecture & Core Blocks

```bash
# Add Feature Blocks
swiftblock add scene Home
swiftblock add usecase Authenticate
swiftblock add repository User
swiftblock add service Network
swiftblock add coordinator MainFlow
swiftblock add component PrimaryButton
swiftblock add mapper UserMapper
swiftblock add validator EmailValidator
swiftblock add entity UserProfile

# Add Core Foundation Blocks
swiftblock core storage AppStorage
swiftblock core network HTTPClient
swiftblock core logger AppLogger
swiftblock core auth SessionManager
swiftblock core analytics AnalyticsEngine
swiftblock core config AppConfig
swiftblock core featureflag RemoteFlags
```

#### Custom Architecture Kits

```bash
# List available kits
swiftblock kit list

# Create a new custom kit
swiftblock kit create feature --blocks scene,usecase,repository,service

# Run kit to generate all composed bricks in one step
swiftblock kit run feature Profile
```

---

## Command Reference

| Command                             | Option / Flag                                                                                            | Description                                           | Default                                                           |
| :---------------------------------- | :------------------------------------------------------------------------------------------------------- | :---------------------------------------------------- | :---------------------------------------------------------------- |
| `swiftblock new <Name>` (or `init`) | `-p, --bundle-prefix`                                                                                    | Set custom bundle identifier prefix                   | `com.company`                                                     |
|                                     | `--tool <tuist\|xcodegen>`                                                                               | Build tool generator backend                          | `tuist`                                                           |
|                                     | `-t, --template-path`                                                                                    | Custom project block template directory               | `/usr/local/share/swiftblock/Blocks/Projects/BaseProject-SwiftUI` |
|                                     | `--dry-run`                                                                                              | Simulate generation without writing to disk           | `false`                                                           |
| `swiftblock add <block> <Name>`     | `scene`, `usecase`, `repository`, `service`, `entity`, `coordinator`, `component`, `mapper`, `validator` | Generate architectural feature module + unit test     | `App/Sources/Features/`                                           |
| `swiftblock core <block> <Name>`    | `storage`, `network`, `logger`, `auth`, `analytics`, `config`, `featureflag`                             | Generate core foundation module + unit test           | `App/Sources/Core/`                                               |
| `swiftblock kit <cmd>`              | `list`, `create`, `run`, `remove`                                                                        | Manage and execute composable architecture kits       |                                                                   |
|                                     | `-h, --help`                                                                                             | Display command usage instructions                    |                                                                   |

---

## Project Configuration (`.swiftblock`)

Every generated project includes a `.swiftblock` configuration file at the project root:

```json
{
  "projectName": "MyApp",
  "bundlePrefix": "com.mycompany",
  "generatorTool": "tuist",
  "paths": {
    "scene": "App/Sources/Features",
    "usecase": "App/Sources/Features",
    "repository": "App/Sources/Features",
    "service": "App/Sources/Features"
  },
  "kits": {
    "feature": ["scene", "usecase", "repository", "service"]
  }
}
```

---

## Building Blocks Structure

Blocks are stored at `/usr/local/share/swiftblock/Blocks/`:

```text
Blocks/
├── Projects/                     # Project Starter Blocks (Tuist & XcodeGen)
│   └── BaseProject-SwiftUI/
│
├── Core/                         # Core Foundation Blocks
│   ├── Storage/                  # Local Persistence Storage
│   ├── Network/                  # HTTP Network Transport
│   ├── Logger/                   # Unified OSLog Logger
│   ├── Auth/                     # Session & Token Manager
│   ├── Analytics/                # Analytics Event Engine
│   ├── Config/                   # Environment Configuration
│   └── FeatureFlag/              # Remote Toggles Engine
│
└── Modules/                      # Feature Architecture Blocks
    ├── Scene/                    # MVVM Scene (View + ViewModel + State)
    ├── UseCase/                  # Domain UseCase (Protocol + Impl)
    ├── Repository/               # Data Repository (Protocol + Impl)
    ├── Service/                  # API Service (Protocol + Impl)
    ├── Entity/                   # Domain Model / DTO
    ├── Coordinator/              # MVVM-C Router Flow
    ├── Component/                # Reusable UI Component
    ├── Mapper/                   # DTO Transformer
    └── Validator/                # Input Validator
```

---

## Local Development & Testing

```bash
# Build release binary locally
swift build -c release

# Run unit test suite (Swift Testing framework)
swift test

# Run End-to-End integration test matrix (12 scenarios)
./Scripts/test_e2e.sh
```

---

## License

Distributed under the MIT License.

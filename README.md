<p align="center">
  <img src="Docs/Assets/SwiftBlock.svg" width="120" height="120" alt="SwiftBlock Logo">
  <h1 align="center">SwiftBlock</h1>
  <p align="center">
    <strong>Production-ready iOS project generator and scaffolding CLI.</strong>
  </p>
  <p align="center">
    <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.10-orange.svg?style=flat-square" alt="Swift 5.10"></a>
    <a href="https://developer.apple.com"><img src="https://img.shields.io/badge/Platform-macOS%2012.0%2B-blue.svg?style=flat-square" alt="Platform macOS"></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg?style=flat-square" alt="License MIT"></a>
  </p>
</p>

---

**SwiftBlock** is a command-line tool designed to instantly scaffold clean, modern SwiftUI Xcode projects and architecture building blocks pre-configured with industry-standard developer tooling.

---

## Key Features

- **Instant Scaffolding**: Generate complete SwiftUI-based Xcode projects with a single command.
- **Architecture Building Blocks**: Generate `scene`, `usecase`, `repository`, and `service` modules directly from your project root.
- **Project Config (.swiftblock)**: Automatic JSON configuration for customizable directory paths per project.
- **Tuist Integration**: Built-in support for Tuist project generation out of the box.
- **Pre-configured Code Quality**: Automatic setup for SwiftLint, SwiftFormat, and pre-commit hooks.
- **Dynamic Bundle Identifiers**: Support for custom organization prefixes (`--bundle-prefix`).

---

## Quick Start

### 1. Installation

Install SwiftBlock globally on your macOS system:

```bash
git clone https://github.com/mrardyan/swiftblock.git
cd swiftblock
chmod +x Scripts/install.sh
./Scripts/install.sh
```

### 2. Usage

#### Initialize a New Project

```bash
# Create a project with default bundle prefix (io.ardyan)
swiftblock init MyApp

# Create a project with custom organization bundle prefix
swiftblock init MyApp --bundle-prefix com.mycompany

cd MyApp
make setup
make generate
```

#### Add Modular Building Blocks

Run these commands from your project root:

```bash
# Add a new MVVM Scene (View + ViewModel + State)
swiftblock add scene Home

# Add a new Domain UseCase
swiftblock add usecase Authenticate

# Add a new Data Repository
swiftblock add repository User

# Add a new API Service
swiftblock add service Network
```

---

## Command Reference

| Command | Option / Flag | Description | Default |
| :--- | :--- | :--- | :--- |
| `swiftblock init <Name>` | `-b, --bundle-prefix` | Set custom bundle identifier prefix | `io.ardyan` |
| | `-t, --template-path` | Use custom template directory path | `/usr/local/share/swiftblock/Templates/Projects/BaseProject-SwiftUI` |
| `swiftblock add scene <Name>` | `-t, --template-path` | Generate MVVM Scene module | `App/Sources/Features/<Name>` |
| `swiftblock add usecase <Name>` | `-t, --template-path` | Generate Domain UseCase module | `App/Sources/Domain/UseCases/<Name>` |
| `swiftblock add repository <Name>` | `-t, --template-path` | Generate Data Repository module | `App/Sources/Data/Repositories/<Name>` |
| `swiftblock add service <Name>` | `-t, --template-path` | Generate API Service module | `App/Sources/Data/Services/<Name>` |
| | `-h, --help` | Show command usage and help | |

---

## Project Configuration (.swiftblock)

Every generated project includes a `.swiftblock` configuration file at the project root:

```json
{
  "projectName": "MyApp",
  "bundlePrefix": "io.ardyan",
  "paths": {
    "scene": "App/Sources/Features",
    "usecase": "App/Sources/Domain/UseCases",
    "repository": "App/Sources/Data/Repositories",
    "service": "App/Sources/Data/Services"
  }
}
```

---

## Building Block Templates

Templates are stored at `/usr/local/share/swiftblock/Templates/`:

```text
Templates/
├── Projects/                     # Project Starter Templates
│   └── BaseProject-SwiftUI/
│       ├── .swiftblock           # Project Config File
│       ├── Project.swift         # Tuist Project Manifest
│       ├── Makefile              # Makefile Automation
│       └── App/                  # Source Directories
│
└── Modules/                      # Architecture Building Block Templates
    ├── Scene/                    # MVVM Scene (View + ViewModel + State)
    ├── UseCase/                  # Domain UseCase (Protocol + Default Impl)
    ├── Repository/               # Data Repository (Protocol + Default Impl)
    └── Service/                  # API Service (Protocol + Default Impl)
```

---

## Local Development & Testing

```bash
# Build release binary locally
swift build -c release

# Run unit test suite (Swift Testing framework)
swift test

# Test executable without global installation
.build/release/swiftblock init SampleApp
```

---

## License

Distributed under the MIT License.
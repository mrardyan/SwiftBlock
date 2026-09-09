# 🛠 SwiftBlock

> Production-ready iOS project generator and scaffolding CLI.

[![Swift 5.10](https://img.shields.io/badge/Swift-5.10-orange.svg?style=flat-square)](https://swift.org)
[![Platform macOS](https://img.shields.io/badge/Platform-macOS%2012.0%2B-blue.svg?style=flat-square)](https://developer.apple.com)
[![License MIT](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)

**SwiftBlock** is a command-line tool designed to instantly scaffold clean, modern SwiftUI Xcode projects pre-configured with industry-standard developer tooling.

---

## ✨ Key Features

- ⚡ **Instant Scaffolding**: Generate complete SwiftUI-based Xcode projects with a single command.
- 🏗️ **Tuist Integration**: Built-in support for Tuist project generation out of the box.
- 🧹 **Pre-configured Code Quality**: Automatic setup for SwiftLint, SwiftFormat, and pre-commit hooks.
- 🏷️ **Dynamic Bundle Identifiers**: Support for custom organization prefixes (`--bundle-prefix`).
- 📁 **Extensible Templates**: Static and customizable Xcode template support.

---

## 🚀 Quick Start

### 1. Installation

Install SwiftBlock globally on your macOS system:

```bash
git clone https://github.com/mrardyan/swiftblock.git
cd swiftblock
chmod +x Scripts/install.sh
./Scripts/install.sh
```

### 2. Usage

Generate a new iOS project anywhere on your Mac:

```bash
# Standard initialization
swiftblock init MyApp

# Custom bundle identifier (e.g. com.mycompany.MyApp)
swiftblock init MyApp --bundle-prefix com.mycompany
```

---

## 📖 Command Reference

| Command | Option / Flag | Description | Default |
| :--- | :--- | :--- | :--- |
| `swiftblock init <Name>` | `-b, --bundle-prefix` | Set custom bundle identifier prefix | `io.ardyan` |
| | `-t, --template-path` | Use custom template directory path | `/usr/local/share/swiftblock/Templates/BaseProject-SwiftUI` |
| | `-h, --help` | Show command usage and help | |

---

## 📁 Template Structure

Templates are stored at: `/usr/local/share/swiftblock/Templates/`

```text
Templates/
└── BaseProject-SwiftUI/
    ├── Project.swift         # Tuist Project Manifest
    ├── App/
    │   ├── Sources/          # App Delegate, Main SwiftUI App & Views
    │   ├── Resources/        # Assets & Plist resources
    │   └── Tests/            # Unit Test Targets
    ├── Scripts/              # Setup scripts & Xcode file templates
    ├── .swiftlint.yml        # SwiftLint Configuration
    └── .swiftformat          # SwiftFormat Configuration
```

Available placeholders:
- `__PROJECT_NAME__`: Replaced with your project name (e.g. `MyApp`).
- `__BUNDLE_PREFIX__`: Replaced with your organization prefix (e.g. `com.mycompany`).

---

## 🛠 Local Development & Testing

```bash
# Build release binary locally
swift build -c release

# Run unit test suite (Swift Testing framework)
swift test

# Test executable without global installation
.build/release/swiftblock init SampleApp
```

---

## 📚 License

Distributed under the MIT License.
# 🛠 swiftblock — iOS Project Generator CLI

A Swift-based command-line tool to quickly scaffold iOS Xcode projects and modules using templates. Built with [`ArgumentParser`](https://github.com/apple/swift-argument-parser) and installable globally.

---

## ✨ Features

- Generate full SwiftUI-based Xcode projects with a single command
- Add new feature modules using templates (planned)
- Replace placeholders in files (e.g. `__PROJECT_NAME__`, `__BUNDLE_PREFIX__`)
- CLI-based, installable globally on any macOS machine
- Static template path (`/usr/local/share/swiftblock/Templates`)
- Supports Tuist, SwiftLint, and SwiftFormat in generated projects

---

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/mrardyan/swiftblock.git
cd swiftblock
```

### 2. Install the CLI Globally

This script will:
- Build the CLI with Swift
- Copy the binary to `/usr/local/bin/swiftblock`
- Copy templates to `/usr/local/share/swiftblock/Templates`

```bash
chmod +x Scripts/install.sh
./Scripts/install.sh
```

---

## 🧪 Usage

Once installed, use the `swiftblock` command globally from any folder.

### Generate a New Project

```bash
swiftblock init MyApp
```
Creates a new iOS project using the `BaseProject-SwiftUI` template with default bundle prefix (`io.ardyan`).

#### Custom Bundle Prefix
```bash
swiftblock init MyApp --bundle-prefix com.mycompany
# or short form:
swiftblock init MyApp -b com.mycompany
```
Creates a project with bundle identifier `com.mycompany.MyApp`.

### Add a Module (Upcoming)

```bash
swiftblock add-module Home
```
*Note: This feature is planned — contribute if you'd like to help!*

---

## 📁 Template Location

Templates should be placed inside:

```
/usr/local/share/swiftblock/Templates/
```

**Example structure:**
```
Templates/
└── BaseProject-SwiftUI/
    ├── Project.swift
    ├── App/
    │   ├── AppDelegate.swift
    │   ├── ContentView.swift
    │   └── Info.plist
    ├── Tests/
    │   └── AppTests.swift
    ├── .swiftlint.yml
    └── .swiftformat
```

Use placeholders like `__PROJECT_NAME__` and `__BUNDLE_PREFIX__` in template files. They will be replaced automatically during generation.

---

## 🔧 Development

To build locally:

```bash
swift build -c release
```

To test without installing:

```bash
.build/release/swiftblock init MyApp
```

To run unit tests:

```bash
swift test
```

---

## 📦 Distribute via Homebrew (optional)

To distribute via Homebrew:

1. Create a new tap repository: `homebrew-swiftblock`
2. Add a formula referencing your latest GitHub release

Users can install via:

```bash
brew install mrardyan/swiftblock/swiftblock
```

---

## 🙌 Contribution

Feel free to open PRs or issues. Ideas for future:
- Add `add-module` command
- Support MVVM or Clean Architecture templates
- Interactive mode

---

## 📚 License

MIT License

---

Need help? Feel free to open an issue!
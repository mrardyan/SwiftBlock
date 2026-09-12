# Getting Started with SwiftBlock

**SwiftBlock** is a modular component engine for modern Swift and Apple engineering. Inspired by Lego building blocks, SwiftBlock enables developers to snap production-ready architecture components directly into their iOS, macOS, and Vapor codebases.

---

## 1. Installation

### Option A: Via Homebrew (Recommended)

```bash
brew install mrardyan/tap/swiftblock
```

### Option B: Build from Source (Makefile)

```bash
git clone https://github.com/mrardyan/swiftblock.git
cd swiftblock
make install
```

### Option C: Mint Package Manager

```bash
mint install mrardyan/swiftblock
```

Verify your installation:

```bash
swiftblock doctor
```

---

## 2. Quick Start Tutorial: Create Your First App in 3 Steps

In this tutorial, you will create a new SwiftUI application and snap production-grade `Network` and `Auth` components, plus a complete `Profile` feature module.

### Step 1: Initialize a Baseplate

Create a new SwiftUI project baseplate named `MyAwesomeApp` powered by **Tuist** (or `--tool xcodegen`):

```bash
swiftblock baseplate MyAwesomeApp --bundle-prefix com.company.app
```

Output:
```
🔹 Initializing SwiftUI baseplate for 'MyAwesomeApp'...
✅ Baseplate created at ./MyAwesomeApp
   - Architecture: Modular SwiftUI
   - Build Tool: Tuist
```

Navigate into your project folder and generate the workspace:

```bash
cd MyAwesomeApp
make setup      # Installs tools, git hooks, and dependencies
make generate   # Generates Xcode workspace (MyAwesomeApp.xcworkspace)
```

---

### Step 2: Snap Infrastructure Components (Bricks)

Add core infrastructure components to your project:

```bash
# Snap Network Transport Engine
swiftblock snap network

# Snap Auth Manager & Secure Storage
swiftblock snap auth
swiftblock snap securestorage
```

What happens under the hood:
1. Component files are created under `App/Sources/Core/`.
2. Dependencies are automatically registered into `DependencyContainer.swift`.
3. Pre-packaged **Swift Testing** unit tests are created in `App/Tests/CoreTests/`.

---

### Step 3: Snap Feature Blueprints (Composition Kits)

To generate a complete Clean Architecture feature (Scene + UseCase + Repository + Service) in a single command, run the `clean-feature` Composition Kit:

```bash
swiftblock kit run clean-feature Profile
```

Generated files:
```
App/Sources/Features/Profile/
├── Presentation/
│   └── ProfileView.swift
├── Domain/
│   └── ProfileUseCase.swift
└── Data/
    ├── ProfileRepository.swift
    └── ProfileService.swift
```

Automatic route injection:
- `ProfileView` navigation route is auto-injected into `AppCoordinator.swift`.

---

## 3. Dry-Run Mode (Simulation)

Want to preview file changes without writing anything to disk? Use `--dry-run`:

```bash
swiftblock snap network --dry-run
```

Output:
```
[Dry-Run] Would write: App/Sources/Core/Network/NetworkService.swift
[Dry-Run] Would write: App/Tests/CoreTests/NetworkServiceTests.swift
[Dry-Run] Would inject: App/Sources/Core/DependencyContainer.swift
```

---

## Next Steps

- Explore [Core Concepts](file:///Users/ardyan/Development/SwiftBlock/Docs/02-Core-Concepts.md) to understand project structure and Stencil variable engine.
- Read the [Baseplates Guide](file:///Users/ardyan/Development/SwiftBlock/Docs/03-Baseplates-Guide.md).
- Browse the complete [Bricks Catalog](file:///Users/ardyan/Development/SwiftBlock/Docs/04-Bricks-Catalog.md).
- Learn how to create [Custom Bricks & Box Registries](file:///Users/ardyan/Development/SwiftBlock/Docs/05-Custom-Bricks-and-Boxes.md).

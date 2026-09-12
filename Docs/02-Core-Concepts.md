# Core Concepts & Architecture

This guide explains the foundational architecture, configuration files, and automatic integration systems powering **SwiftBlock**.

---

## 1. The Building Block Architecture

SwiftBlock uses a clear hierarchy to manage modular Swift components:

```
                            ┌─────────────────────────┐
                            │        Baseplate        │
                            │  (Project Starter App)  │
                            └────────────┬────────────┘
                                         │
                 ┌───────────────────────┴───────────────────────┐
                 ▼                                               ▼
      ┌─────────────────────┐                         ┌─────────────────────┐
      │     Composition     │                         │    Modular Bricks   │
      │        Kits         │                         │ (Individual Blocks) │
      │ (Feature Blueprints)│                         └─────────────────────┘
      └─────────────────────┘
```

| Term | Concept | Purpose |
|---|---|---|
| **Baseplate** | Project Starter | Modular iOS/macOS SwiftUI or Vapor backend project template created via `swiftblock baseplate`. |
| **Brick** | Code Component Block | Production-ready Swift component template (`Network`, `Scene`, `Storage`) attached via `swiftblock snap`. |
| **Kit** | Architectural Blueprint | Pre-configured batch template that generates multiple bricks at once (e.g. `clean-feature`). |
| **Box** | Remote Component Registry | Git repository containing custom brick components shared across team monorepos. |

---

## 2. Automatic Dependency Registration & Integration

When you run `swiftblock snap <brick>`, SwiftBlock does not just drop isolated files into your project. It automatically integrates them into your codebase:

### A. Dependency Injection Auto-Registration

Given a target file like `App/Sources/Core/DependencyContainer.swift` containing marker comments:

```swift
// MARK: - Register Services
```

Executing `swiftblock snap network` automatically injects the registration code:

```swift
// MARK: - Register Services
container.register(NetworkServiceProtocol.self) { _ in
    NetworkService(timeoutInterval: 30)
}
```

### B. Navigation & Route Auto-Wiring

When snapping UI or Feature Bricks (e.g. `swiftblock snap scene Home`), SwiftBlock inspects `AppCoordinator.swift` and injects route navigation handling:

```swift
enum AppRoute {
    case home
}

@ViewBuilder
func buildScene(for route: AppRoute) -> some View {
    switch route {
    case .home:
        HomeView(viewModel: HomeViewModel())
    }
}
```

---

## 3. Stencil Variable Engine & Interactive Wizard Mode

Every Brick in SwiftBlock uses **Stencil template syntax**. Bricks declare input variables in their `brick.yml` manifest.

### Interactive Wizard Mode
If you run `swiftblock snap` without providing required variables, SwiftBlock launches an interactive terminal wizard:

```bash
$ swiftblock snap network
? Default request timeout in seconds? (30): 60
```

### CLI Variable Overrides
Pass variables directly on the command line using `--var key=value` or `-v key=value`:

```bash
swiftblock snap network --var timeoutInterval=60
```

---

## 4. Project vs. Runtime Configuration

In SwiftBlock, configuration is clearly split between **Project (Build-Time)** settings and **Runtime (App-Level)** settings:

```
                            ┌─────────────────────────────────┐
                            │    Configuration Scope Split    │
                            └────────────────┬────────────────┘
                                             │
                    ┌────────────────────────┴────────────────────────┐
                    ▼                                                 ▼
      ┌───────────────────────────┐                     ┌───────────────────────────┐
      │   Project Configuration   │                     │   Runtime Configuration   │
      │   (.swiftblock/config.yml)│                     │  (AppConfig.swift Brick)  │
      ├───────────────────────────┤                     ├───────────────────────────┤
      │ • Generator Tool (Tuist)  │                     │ • Staging vs Prod URLs    │
      │ • Module Output Paths     │                     │ • Network Timeout Rules   │
      │ • Kit Blueprints          │                     │ • In-App Feature Flags    │
      └───────────────────────────┘                     └───────────────────────────┘
```

### A. Project Configuration (`.swiftblock/config.yml`)
Controls **CLI code generation**, destination folder paths, build tool choice, and kit composition recipes at development time:

```yaml
projectName: MyAwesomeApp
bundlePrefix: com.company.app
generatorTool: tuist # Options: tuist | xcodegen

paths:
  scene: App/Sources/Features
  usecase: App/Sources/Features
  repository: App/Sources/Features
  network: App/Sources/Core/Network
  storage: App/Sources/Core/Storage

kits:
  clean-feature:
    - scene
    - usecase
    - repository
    - service
```

### B. Runtime Configuration (`swiftblock snap config`)
Generates in-app **Swift execution configuration** (`AppConfig.swift`) for application runtime behavior:

```swift
// Generated App/Sources/Core/Config/AppConfig.swift
public struct AppConfig {
    public static let environment: AppEnvironment = .staging
    public static let apiBaseURL = URL(string: "https://api.staging.example.com")!
    public static let defaultTimeoutInterval: TimeInterval = 30
}
```

---

## Next Steps

- Read the [Baseplates Guide](file:///Users/ardyan/Development/SwiftBlock/Docs/03-Baseplates-Guide.md).
- Explore the complete list of available components in the [Bricks Catalog](file:///Users/ardyan/Development/SwiftBlock/Docs/04-Bricks-Catalog.md).
- Learn how to manage team component repositories in [Custom Bricks & Boxes](file:///Users/ardyan/Development/SwiftBlock/Docs/05-Custom-Bricks-and-Boxes.md).

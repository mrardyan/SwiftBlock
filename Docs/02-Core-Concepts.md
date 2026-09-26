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

---

## 3. Structured Composing Engine & Flavors

SwiftBlock features a **Structured Composing Engine** that automatically analyzes dependency graphs, detects incompatible architecture conflicts, and renders conditional Swift template blocks.

### A. Automatic Dependency Graph Resolution
- **Mandatory Dependencies**: Automatically resolved and generated prior to the target brick (e.g. `usecase` auto-snaps `asyncusecase`).
- **Optional Dependencies & Auto-Wiring**: Selected via `--with-optional` or `--all-optional` (e.g., adding `exponentialbackoff` automatically wires `.withRetry()` decorator into UseCases).
- **Conflict Guardrails**: Detects incompatible bricks (e.g., `auth` vs `vaporauth`) both within the resolution plan and against already-installed bricks in the project.

### B. Interactive Flavors System
Bricks can declare `flavors` in their `brick.yml` to allow developers to customize generation interactively or via `--flavor <key>=<value>`:

```bash
# Snap Scene with legacy Combine ObservableObject instead of iOS 17 @Observable
swiftblock snap scene Profile --flavor stateStyle=combine

# Snap Repository with offline-first local database caching strategy
swiftblock snap repository User --flavor strategy=offline-first
```

### C. Template Engine & Conditional Code Generation
Bricks use conditional template evaluation to generate clean code without clutter:

```swift
{{#if stateStyle == 'combine'}}
final class {{MODULE_NAME}}ViewModel: ObservableObject {
    @Published var state: ViewState = .idle
}
{{else}}
@Observable
final class {{MODULE_NAME}}ViewModel {
    var state: ViewState = .idle
}
{{/if}}
```

### D. Interactive Wizard Mode & CLI Overrides
If required variables or flavors are not supplied via CLI flags, SwiftBlock launches an arrow-key terminal wizard menu:

```bash
$ swiftblock snap scene Profile
┌  Configure Flavors for 'scene'
│
│  ?  Select state observation style (↑/↓ to navigate, ESC/Ctrl+C to exit)
│    ❯ @Observable (Swift 5.9+ / iOS 17+) (Default)
│      ObservableObject (Combine Legacy)
```

CLI variables can also be passed directly using `--var key=value` or `-v key=value`:

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

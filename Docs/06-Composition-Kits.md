# Composition Kits (Architectural Blueprints)

A **Composition Kit** is an architectural blueprint that batches multiple Brick component templates into a single command execution. Instead of snapping `scene`, `usecase`, `repository`, and `service` individually, a Kit generates and wires an entire feature layer at once.

---

## 1. Running a Composition Kit (`swiftblock kit run`)

To generate a complete Clean Architecture feature module named `Payment`:

```bash
swiftblock kit run clean-feature Payment
```

Generated files and automatic integrations:
```
App/Sources/Features/Payment/
├── Presentation/
│   ├── PaymentView.swift
│   └── PaymentViewModel.swift
├── Domain/
│   └── PaymentUseCase.swift
└── Data/
    ├── PaymentRepository.swift
    └── PaymentService.swift
```

Automatic Integrations:
- `PaymentView` navigation route is auto-injected into `AppCoordinator.swift`.
- `PaymentService` is auto-registered into `DependencyContainer.swift`.
- Swift Testing unit test suites are generated in `App/Tests/FeatureTests/PaymentTests.swift`.

---

## 2. Built-in Blueprint: `clean-feature`

Out of the box, every project includes the `clean-feature` blueprint:

```
                  ┌─────────────────────────────────┐
                  │ swiftblock kit run clean-feature│
                  └────────────────┬────────────────┘
                                   │
      ┌────────────────┬───────────┴───────────┬────────────────┐
      ▼                ▼                       ▼                ▼
┌───────────┐    ┌───────────┐           ┌───────────┐    ┌───────────┐
│   Scene   │    │  UseCase  │           │ Repository│    │  Service  │
│(View + VM)│    │ (Domain)  │           │   (Data)  │    │  (Remote) │
└───────────┘    └───────────┘           └───────────┘    └───────────┘
```

---

## 3. Defining Custom Kits (`.swiftblock/config.yml`)

You can define custom feature blueprints for your project directly inside `.swiftblock/config.yml`:

```yaml
kits:
  # Custom CRUD Blueprint
  crud-feature:
    - scene
    - usecase
    - repository

  # Custom Micro-Feature Blueprint
  micro-feature:
    - scene
    - service
```

Run your custom blueprint anytime:

```bash
swiftblock kit run crud-feature Settings
```

---

## 4. CLI Kit Management Commands

### Add a Kit via CLI (`swiftblock kit add`)

Define a new composition kit shortcut directly from terminal:

```bash
swiftblock kit add full-feature scene usecase repository service mapper
```

---

### Create an Interactive Blueprint (`swiftblock kit create`)

Create a custom kit interactively using terminal prompts:

```bash
swiftblock kit create
```

---

### List Available Kits (`swiftblock kit list`)

View all built-in and project-configured composition blueprints:

```bash
swiftblock kit list
```

Output:
```
Available Composition Kits:
  • clean-feature [scene, usecase, repository, service]
  • crud-feature  [scene, usecase, repository]
  • micro-feature [scene, service]
```

---

## Next Steps

- Consult the complete [CLI Reference](file:///Users/ardyan/Development/SwiftBlock/Docs/07-CLI-Reference.md).

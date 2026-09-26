# Custom Bricks & Box Registries

This guide explains how to create **Custom Bricks**, override built-in templates, write manifest specifications (`brick.yml`), and publish/share brick repositories across your engineering team using **Box Registries**.

---

## 1. Local Project Overrides (`.swiftblock/blocks/`)

To override a built-in brick or add custom brick templates specifically for your current project:

1. Create a directory named `.swiftblock/blocks/` in your project root.
2. Copy or create your custom brick template inside `.swiftblock/blocks/my-brick/`.
3. When running `swiftblock snap my-brick`, SwiftBlock automatically prioritizes local overrides in `.swiftblock/blocks/` before searching built-in bricks.

---

## 2. Writing a Custom Brick Manifest (`brick.yml`)

Every custom Brick directory must contain a manifest file named `brick.yml` (or `block.json`).

### Example `brick.yml` Manifest:

```yaml
name: repository
category: feature
description: "Clean Architecture Repository Pattern"
version: "1.0.0"
defaultPath: "App/Sources/Features"

dependencies:
  mandatory:
    - name: transforming
      description: "Model transformation and mapping protocol"
  optional:
    - name: network
      description: "HTTP remote API transport client"
    - name: storage
      description: "Local persistence database engine"
    - name: logger
      description: "OSLog structured diagnostic logger"

flavors:
  strategy:
    prompt: "Select repository data caching strategy"
    default: remote-only
    options:
      - id: remote-only
        title: "Remote Only"
        description: "Fetch directly from backend API without local caching"
        variables:
          hasLocalCache: false
      - id: offline-first
        title: "Offline First"
        description: "Cache remote responses in local database with fallback"
        variables:
          hasLocalCache: true
        dependencies:
          optional:
            - name: storage

variables:
  - name: duration
    type: string
    prompt: "Default cache TTL in seconds?"
    default: "300"

injections:
  - target: "App/Sources/Core/DependencyContainer.swift"
    marker: "// MARK: - Register Repositories"
    content: "        container.register({{MODULE_NAME}}RepositoryProtocol.self) { _ in Default{{MODULE_NAME}}Repository() }"

hooks:
  pre_snap:
    - "echo 'Preparing repository brick generation...'"
  post_snap:
    - "make generate"
```

### Manifest Fields Reference

| Field | Type | Description |
|---|---|---|
| `name` | String | Unique identifier of the brick used in `swiftblock snap <name>`. |
| `category` | String | Functional category (`feature`, `core`, `utils`, `config`). |
| `description` | String | Description displayed during `swiftblock box list` or TUI prompts. |
| `defaultPath` | String | Default directory path where files are written. |
| `dependencies` | Object | Architectural dependency graph rules (`mandatory`, `optional`, `conflicts`). |
| `flavors` | Object | Interactive option groups (`prompt`, `default`, `options`) that configure template variables and dependencies. |
| `variables` | Array | List of template variables prompted interactively or overridden via `--var`. |
| `injections` | Array | Code injection rules targetting existing files in the user project. |
| `hooks` | Object | Shell commands executed before (`pre_snap`) or after (`post_snap`) generation. |

---

## 3. Snapping Direct from Git URLs

You can snap custom bricks directly from a public or private Git repository URL without adding a registry:

```bash
# Snap single brick from Git URL
swiftblock snap https://github.com/mycompany/swiftui-toast-brick.git Toast

# Snap brick from monorepo subpath using URL fragment (#)
swiftblock snap https://github.com/mycompany/ios-bricks.git#Bricks/Toast Toast
```

---

## 4. Team Box Registries (`swiftblock box`)

Box Registries allow engineering organizations to manage a central Git repository containing team-standardized Bricks.

### Register a Team Box (`swiftblock box add`)

Add a remote Git repository as a team Box registry:

```bash
swiftblock box add company https://github.com/company/ios-bricks.git
```

Now any developer on the team can snap bricks from the `company` registry:

```bash
swiftblock snap company/payment-gateway Checkout
```

---

### Sync Registry Updates (`swiftblock box update`)

Pull the latest brick templates from registered team boxes:

```bash
# Update all registered boxes
swiftblock box update

# Update a specific box registry
swiftblock box update company
```

---

### List Registries & Bricks (`swiftblock box list`)

View all local, built-in, and remote Box bricks available on your system:

```bash
swiftblock box list
```

---

### Audit Brick Manifest Compliance (`swiftblock box validate`)

Before publishing a custom brick, validate its manifest and Stencil syntax:

```bash
swiftblock box validate ./MyCustomBrick
```

Output:
```
🔹 Validating brick at './MyCustomBrick'...
✅ Manifest brick.yml is valid.
✅ Stencil template syntax OK.
```

---

### Publish a Custom Brick (`swiftblock box publish`)

Package and push a custom brick directory to your team's Box Git repository:

```bash
swiftblock box publish ./MyCustomBrick --target-repo https://github.com/company/ios-bricks.git
```

---

## Next Steps

- Explore [Composition Kits](file:///Users/ardyan/Development/SwiftBlock/Docs/06-Composition-Kits.md) to batch generate multiple bricks.
- Review the complete [CLI Reference](file:///Users/ardyan/Development/SwiftBlock/Docs/07-CLI-Reference.md).

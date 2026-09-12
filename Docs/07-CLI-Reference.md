# CLI Command Reference

This is the exhaustive command-line interface reference for **SwiftBlock**.

---

## 1. `swiftblock baseplate`

Initialize a brand-new production-ready Swift application baseplate.

### Aliases
`swiftblock init`, `swiftblock new`

### Syntax
```bash
swiftblock baseplate <ProjectName> [options]
```

### Options & Flags
| Flag | Description | Default |
|---|---|---|
| `--bundle-prefix <prefix>` | Reverse domain bundle identifier prefix. | `com.company` |
| `--tool <tuist\|xcodegen>` | Build system manifest tool. | `tuist` |
| `--dry-run` | Simulate baseplate creation without writing to disk. | `false` |

### Examples
```bash
# Create SwiftUI project using Tuist
swiftblock baseplate MyApp --bundle-prefix com.mycompany

# Create project using XcodeGen
swiftblock baseplate MyApp --tool xcodegen

# Dry-run simulation
swiftblock baseplate MyApp --dry-run
```

---

## 2. `swiftblock snap`

Snap a built-in or custom Brick component into your current project codebase.

### Aliases
`swiftblock add`, `swiftblock use`

### Syntax
```bash
swiftblock snap <brick-name-or-git-url> [Name] [options]
```

### Options & Flags
| Flag | Description | Default |
|---|---|---|
| `--var <key=value>`, `-v` | Pass custom Stencil template prompt variables. | — |
| `--path <customPath>` | Override default destination output directory. | Set in `config.yml` |
| `--dry-run` | Preview file generations and injection diffs. | `false` |

### Examples
```bash
# Snap infrastructure brick
swiftblock snap network

# Snap feature brick with custom module name
swiftblock snap scene Home

# Pass Stencil template variables
swiftblock snap network --var timeoutInterval=60

# Snap directly from Git URL
swiftblock snap https://github.com/mycompany/swiftui-toast-brick.git Toast
```

---

## 3. `swiftblock kit`

Manage and execute multi-brick composition blueprints.

### Subcommands

#### `swiftblock kit run <kit-name> [Name]`
Execute a batch composition blueprint for a specific module name.

```bash
swiftblock kit run clean-feature Profile
```

#### `swiftblock kit add <name> <bricks...>`
Define a new kit blueprint in your CLI setup.

```bash
swiftblock kit add full-feature scene usecase repository service
```

#### `swiftblock kit create`
Create a custom composition blueprint interactively.

```bash
swiftblock kit create
```

#### `swiftblock kit list`
Display all available composition kits.

```bash
swiftblock kit list
```

---

## 4. `swiftblock box`

Manage team Box repositories and component registries.

### Subcommands

#### `swiftblock box add <name> <git-url>`
Register a remote Git brick repository.

```bash
swiftblock box add team-box https://github.com/company/ios-bricks.git
```

#### `swiftblock box list`
List all registered Box stores and brick components.

```bash
swiftblock box list
```

#### `swiftblock box update [name]`
Fetch latest brick template updates from registered Box repositories.

```bash
swiftblock box update
```

#### `swiftblock box remove <name>`
Unregister a Box repository.

```bash
swiftblock box remove team-box
```

#### `swiftblock box validate [path]`
Validate a custom brick manifest (`brick.yml`) for compliance.

```bash
swiftblock box validate ./MyBrick
```

#### `swiftblock box publish [path]`
Publish a custom brick directory to a remote Box Git repository.

```bash
swiftblock box publish ./MyBrick
```

---

## 5. `swiftblock doctor`

Run a diagnostic suite to verify your local environment, Xcode setup, Tuist/XcodeGen dependencies, and `.swiftblock/config.yml` integrity.

```bash
swiftblock doctor
```

Output:
```
🔹 Running SwiftBlock Diagnostics...
✅ Swift Compiler (5.10) detected.
✅ Tuist CLI (4.12.0) detected.
✅ Git CLI detected.
✅ Project config .swiftblock/config.yml is valid.
```

---

## 6. `swiftblock rename`

Refactor and rename project names or module references across build manifests and source files cleanly.

```bash
swiftblock rename OldAppName NewAppName
```

---

## 7. `swiftblock ide setup`

Configure IDE shortcuts and code completion snippets for Xcode or VS Code.

```bash
swiftblock ide setup
```

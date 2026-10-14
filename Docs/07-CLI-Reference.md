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
| `--flavor <key=value>` | Select a flavor configuration (e.g. `--flavor strategy=offline-first` or `--flavor stateStyle=combine`). | Default option defined in `brick.yml` |
| `--with-optional <deps>` | Comma-separated list of optional dependencies to resolve and auto-wire. | — |
| `--all-optional` | Automatically snap and wire all declared optional dependencies. | `false` |
| `--no-deps` | Skip automatic resolution and snapping of mandatory dependencies. | `false` |
| `--var <key=value>`, `-v` | Pass custom template prompt variables. | — |
| `--path <customPath>` | Override default destination output directory. | Set in `config.yml` |
| `--dry-run` | Preview file generations and injection diffs. | `false` |

### Examples
```bash
# Snap infrastructure brick with flavor and optional decorator dependencies
swiftblock snap network --flavor client=urlsession --with-optional circuitbreaker,exponentialbackoff

# Snap feature scene with legacy Combine state style
swiftblock snap scene Profile --flavor stateStyle=combine

# Snap repository with offline-first caching strategy
swiftblock snap repository User --flavor strategy=offline-first

# Pass custom template variables
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

## 5. `swiftblock agent setup`

Embed AI agent skills and engineering guidelines for AI coding assistants (Google Antigravity, Claude Code, Cursor, and GitHub Copilot) directly into your project.

### Syntax
```bash
swiftblock agent setup [options]
```

### Options & Flags
| Flag | Description | Default |
|---|---|---|
| `-p, --path <path>` | Path to project root directory. | Current working directory |
| `-t, --target <targets>` | Target AI assistants (`all`, `antigravity`, `cursor`, `claude`, `copilot`). | `all` |
| `--no-cursor` | Skip generating Cursor rules (`.cursor/rules/swiftblock.mdc`). | `false` |

### Examples
```bash
# Embed AI agent skills for all supported assistants
swiftblock agent setup

# Target only Antigravity and Claude Code
swiftblock agent setup --target antigravity,claude
```

---

## 6. `swiftblock doctor`

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

## 7. `swiftblock rename`

Refactor and rename project names or module references across build manifests and source files cleanly.

```bash
swiftblock rename OldAppName NewAppName
```

---

## 8. `swiftblock ide setup`

Configure IDE shortcuts and code completion snippets for Xcode or VS Code.

```bash
swiftblock ide setup
```

---

## 9. `swiftblock completion`

Generate shell autocompletion scripts for Zsh, Bash, or Fish.

```bash
# Zsh completion setup
swiftblock completion zsh > ~/.zfunc/_swiftblock
echo 'fpath=(~/.zfunc $fpath)' >> ~/.zshrc
echo 'autoload -Uz compinit && compinit' >> ~/.zshrc

# Bash completion setup
swiftblock completion bash > ~/.swiftblock-completion.bash
echo 'source ~/.swiftblock-completion.bash' >> ~/.bashrc

# Fish completion setup
swiftblock completion fish > ~/.config/fish/completions/swiftblock.fish
```

---

## 10. Developer & Contributor Workflow (`make`)

When contributing to SwiftBlock or working locally in the repository, use the standardized `Makefile` workflow commands:

| Command | Description |
|---|---|
| `make setup` | Verify dependencies (Swift 5.10+, Xcode, linters), install git pre-commit hooks, and compile CLI binary. |
| `make dev` | Start a new standardized branch (`feat/*`, `fix/*`, `docs/*`, `chore/*`, `test/*`) with automatic `origin/main` sync. Supports `TYPE=<type> NAME=<name>`. |
| `make sync` | Fetch latest `origin/main` and rebase your active feature branch to prevent merge conflicts. |
| `make test` | Run automated test suites (default: unit + template tests). Options: `make test SUITE=unit\|templates\|e2e\|all`. |
| `make verify` | Run the complete pre-PR quality gate pipeline: formatting (`make format`), linter (`make lint`), and all test suites. |
| `make hotfix` | Cut an isolated patch branch directly from a specific release tag. Supports `TAG=<tag> NAME=<name>`. |
| `make release` | Verify test suites, create an annotated SemVer Git tag, push to origin, and update `Formula/swiftblock.rb`. |
| `make build` | Compile the SwiftBlock CLI binary in release mode (`.build/release/swiftblock`). |
| `make install` | Compile and install the CLI binary and building block assets to system (`/usr/local/bin` and `/usr/local/share/swiftblock`). |
| `make clean` | Clean build artifacts and SPM caches. |

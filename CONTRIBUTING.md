# Contributing to SwiftBlock

Thank you for your interest in contributing to **SwiftBlock**! We welcome contributions from developers of all skill levels. Whether you are adding a new architectural Brick, improving documentation, or fixing bugs, this guide outlines the process.

---

## 1. Prerequisites

Before developing SwiftBlock locally, ensure your machine meets the following requirements:
- **macOS**: 12.0 (Monterey) or newer (macOS 14+ recommended)
- **Swift**: 5.10 or newer (Xcode 15+)
- **Homebrew packages** (recommended for linters):
  ```bash
  brew install swiftlint swiftformat
  ```

---

## 2. Quick Setup

Clone the repository and run the setup script to configure your environment and install automated pre-commit guardrails:

```bash
git clone https://github.com/mrardyan/SwiftBlock.git
cd SwiftBlock
make setup
```

`make setup` will:
- Validate your Swift toolchain and linters
- Install Git pre-commit hooks (`.githooks/pre-commit`)
- Compile the release CLI binary

---

## 3. Development Workflow

SwiftBlock follows **GitHub Flow**. Direct commits to the `main` branch are blocked. Always create a dedicated branch for your work.

### Starting a New Task

Use `make dev` to automatically pull latest changes from `main` and checkout a standardized branch:

```bash
# Interactive mode (prompts for type and branch name)
make dev

# Or direct argument mode:
make dev TYPE=feat NAME=token-refresher
# or
make dev TYPE=fix NAME=yaml-parser-crash
```

#### Allowed Branch Types:
- `feat/` : New capability, architectural brick, or CLI subcommand
- `fix/` : Bug fix or compiler issue resolution
- `docs/` : Guide or documentation improvement
- `chore/` : Tooling, dependency, or configuration update
- `test/` : Adding or refactoring automated tests

### Keeping in Sync

If `main` has progressed while you are working, rebase your branch smoothly:

```bash
make sync
```

---

## 4. Coding & Testing Standards

### Code Formatting & Linting

SwiftBlock enforces strict style rules using `SwiftFormat` and `SwiftLint`.

```bash
# Auto-format and auto-fix linter issues
make format

# Run linter checks
make lint
```

### Running Test Suites

Before opening a Pull Request, ensure all tests pass:

```bash
# Run unit & template validation tests (default)
make test

# Or run a specific test tier:
make test SUITE=unit       # Swift unit tests only
make test SUITE=templates  # Brick template validation tests only
make test SUITE=e2e        # Full end-to-end integration test matrix
make test SUITE=all        # Execute all test tiers
```

### The Pre-PR Verification Shortcut

Run the unified verification command that runs formatting, linting, unit tests, and template tests in sequence:

```bash
make verify
```

---

## 5. Commit Guidelines

We follow **Conventional Commits**:

```
<type>(<scope>): <short description>
```

Examples:
- `feat(bricks): add token refresher brick with single-flight actor mutex`
- `fix(core): improve yaml list parsing and test converter`
- `docs(readme): add installation guide for Homebrew`
- `test(e2e): add scenario 21 for swiftblock agent setup`

---

## 6. Submitting a Pull Request

1. Push your branch to GitHub:
   ```bash
   git push origin feat/your-feature-name
   ```
2. Open a Pull Request on GitHub targeting the `main` branch.
3. Fill out the **Pull Request Template** checklist.
4. Ensure all automated GitHub Actions CI checks turn green.
5. Once reviewed and approved by maintainers, your PR will be **Squashed and Merged** into `main`.

---

## 7. Community & Code of Conduct

All contributors are expected to uphold our [Code of Conduct](CODE_OF_CONDUCT.md). Please treat all community members with respect and kindness.

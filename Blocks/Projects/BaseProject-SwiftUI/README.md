# __PROJECT_NAME__
<!-- Add __PROJECT_NAME__ description here -->

## Features
<!-- Add __PROJECT_NAME__ features here -->

## Requirements
- macOS 12.0+
- Xcode 15.0+
- Homebrew

## Getting Started

To set up the project and install all required dependencies (Tuist, SwiftLint, SwiftFormat, pre-commit hooks, and Xcode file templates), run:

```bash
make setup
```

Once setup is complete, generate the Xcode project workspace:

```bash
make generate
```

## Available Commands (Makefile)

| Command | Description |
| :--- | :--- |
| `make setup` | Run setup script to install tools & pre-commit hooks |
| `make generate` | Generate Xcode workspace using Tuist |
| `make lint` | Run SwiftLint code analysis |
| `make format` | Run SwiftFormat code formatter |
| `make test` | Run unit tests using Tuist |
| `make clean` | Clean Tuist cache and build artifacts |
| `make edit` | Open Tuist configuration in Xcode |

## Project Structure
- **App**: Contains main app sources (`Sources/`), resources (`Resources/`), and unit tests (`Tests/`).
- **Tuist**: Tuist configuration directory.
- **Scripts**: Project setup and configuration scripts.
- **.XcodeFileTemplates**: Custom Xcode file templates.

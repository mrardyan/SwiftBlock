# __PROJECT_NAME__

High-performance Swift backend web API service powered by **Vapor** and **SwiftBlock**.

## Features

- 💧 **Vapor 4**: Async/await Swift backend HTTP server architecture.
- 🏥 **Health Check API**: Built-in `GET /health` service diagnostic endpoint.
- 🧪 **XCTVapor Testing**: Pre-packaged automated HTTP integration test suite.
- 🐳 **Docker & Docker Compose**: Ready-to-deploy multi-stage Docker build and compose configuration.
- 🛠️ **Developer Tooling**: Makefile automation, SwiftLint code analysis, and SwiftFormat enforcement.

## Requirements

- macOS 13.0+ or Linux (Ubuntu 22.04 / 24.04)
- Swift 5.10+
- Docker (optional, for containerization)

## Getting Started

### 1. Local Setup

Install dependencies and git pre-commit hooks:

```bash
make setup
```

### 2. Build & Run Local API Server

```bash
make build
make run
```

The API server will listen on `http://localhost:8080`.

Test the health endpoint:

```bash
curl http://localhost:8080/health
```

### 3. Run Test Suite

```bash
make test
```

### 4. Containerized Deployment (Docker)

```bash
# Build Docker image
make docker-build

# Run container locally on port 8080
make docker-run
```

Or using Docker Compose:

```bash
docker-compose up --build
```

## Available Makefile Commands

| Command | Description |
| :--- | :--- |
| `make setup` | Install dependencies and pre-commit hooks |
| `make build` | Compile Vapor server binary |
| `make run` | Start local API web server (`http://localhost:8080`) |
| `make test` | Run XCTVapor unit and integration tests |
| `make lint` | Run SwiftLint code analysis |
| `make format` | Run SwiftFormat code formatting |
| `make docker-build` | Build release Docker image |
| `make docker-run` | Launch Docker container |
| `make clean` | Clean SPM build artifacts |

## Project Structure

```
__PROJECT_NAME__/
├── Sources/
│   ├── App/
│   │   ├── Controllers/
│   │   │   └── HealthController.swift
│   │   ├── configure.swift
│   │   ├── entrypoint.swift
│   │   └── routes.swift
│   └── Run/
│       └── main.swift
├── Tests/
│   └── AppTests/
│       └── AppTests.swift
├── Dockerfile
├── docker-compose.yml
├── Makefile
├── Package.swift
└── README.md
```

# SwiftBlock Project Guidelines for AI Agents

This repository is built with **SwiftBlock**. Follow these conventions:

## 1. Feature & Architecture Scaffolding
- Do NOT create architecture boilerplate (Views, ViewModels, UseCases, Repositories, Services) manually from scratch.
- Use `swiftblock snap <brick> <Name>` (e.g., `swiftblock snap scene Profile` or `swiftblock snap service User`).
- For complete clean feature modules, use `swiftblock kit add clean-feature <ModuleName>`.

## 2. Core & Foundation Infrastructure
- Use existing Core foundation modules or snap them via `swiftblock snap <brick>` (e.g., `network`, `storage`, `keychain`, `auth`, `logger`).

## 3. Environment & Diagnostics
- Run `swiftblock doctor` to verify project environment health and dependencies.
- Build & Test: Use `make build` and `make test`.
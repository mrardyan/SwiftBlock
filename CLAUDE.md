# SwiftBlock Guidelines (Claude Code)

This repository is built with **SwiftBlock** for modular architecture and component scaffolding.

## Golden Rules
- DO NOT create boilerplate Swift files (Views, ViewModels, UseCases, Repositories, Services) from scratch.
- Use the SwiftBlock CLI:
  - `swiftblock snap <brick> <Name>` (e.g., `swiftblock snap scene Profile`)
  - `swiftblock kit add clean-feature <ModuleName>`
- Run `swiftblock doctor` to verify environment and dependencies.

## Key Brick Catalog
- **Feature**: `scene`, `usecase`, `repository`, `service`, `entity`, `coordinator`
- **Core**: `network`, `storage`, `keychain`, `auth`, `logger`, `cache`, `notification`, `websocket`
- **Config & Utils**: `config`, `featureflag`, `deeplink`, `validator`, `theme`, `font`

## Development Commands
- Build: `make build`
- Test: `make test`
# SwiftBlock Instructions (GitHub Copilot)

This repository uses **SwiftBlock** for modular scaffolding and architectural components.

## Scaffolding Instructions
When assisting the developer in adding new features, views, services, or domain logic:
- Recommend and use `swiftblock snap <brick> <Name>` or `swiftblock kit add clean-feature <Module>`.
- Available generative bricks: `scene`, `usecase`, `repository`, `service`, `entity`, `coordinator`.
- Available foundation singletons: `network`, `storage`, `keychain`, `auth`, `logger`, `config`.
- Do not write repetitive boilerplate architecture files from scratch.
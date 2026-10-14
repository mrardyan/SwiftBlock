import Foundation

public enum AgentSkillTemplates {
    public static let skillMarkdown = """
    ---
    name: swiftblock
    description: >-
      Use this skill whenever working in this project to scaffold or generate new iOS/Swift
      features, architectural components (MVVM, Clean Architecture, Scene, UseCase, Repository, Service, Entity, Coordinator),
      foundation bricks (Network, Storage, Keychain, Auth, Logger, Cache), composition kits, or to run project diagnostics.
    ---

    # SwiftBlock Architectural Scaffolding & Brick Catalog

    This project uses **SwiftBlock** for modular architecture and component generation.
    Instead of writing boilerplate Swift files or architectures by hand, use the `swiftblock` CLI.

    ## Golden Rules for AI Agents
    1. **Always Prefer SwiftBlock CLI**: When asked to create or scaffold a new feature, scene, service,
       repository, usecase, or foundation layer, run `swiftblock snap` or `swiftblock kit add` rather than creating files manually.
    2. **Post-Scaffold Customization**: After scaffolding, customize only the generated model properties, endpoints, or UI layouts.

    ---

    ## 📚 Complete Brick Catalog

    ### 1. Feature Bricks (Generative)
    - `swiftblock snap scene <Name>`: MVVM View + ViewModel + State
    - `swiftblock snap usecase <Name>`: Domain Business Logic Protocol & Implementation
    - `swiftblock snap repository <Name>`: Data Repository Protocol & Implementation
    - `swiftblock snap service <Name>`: API Service Client & Endpoint
    - `swiftblock snap entity <Name>`: Domain Model & DTO Structs
    - `swiftblock snap coordinator <Name>`: Navigation Flow & Coordinator Router

    ### 2. Multi-Brick Composition Kits
    - `swiftblock kit add clean-feature <Module>`: Snaps Scene + UseCase + Repository + Service
    - `swiftblock kit add mvvm-c <Module>`: Snaps Scene + Coordinator
    - `swiftblock kit list`: List all available composition kits

    ### 3. Core & Infrastructure Bricks (Foundation Singletons)
    - `swiftblock snap network`: Async/Await HTTP Client & Router
    - `swiftblock snap storage`: SwiftData / CoreData Persistence Engine
    - `swiftblock snap keychain`: Secure Keychain Storage Wrapper
    - `swiftblock snap auth`: Authentication Token & Session Manager
    - `swiftblock snap cache`: In-Memory & Disk Cache
    - `swiftblock snap logger`: OSLog Unified Logging Wrapper
    - `swiftblock snap notification`: Push & Local Notification Scheduler
    - `swiftblock snap websocket`: Real-time WebSocket Client
    - `swiftblock snap eventbus`: Reactive Publisher/Subscriber Bus
    - `swiftblock snap localization`: Localized String & Pluralization Helpers

    ### 4. Configuration & Utility Bricks
    - `swiftblock snap config`: Multi-environment (.xcconfig) Manager
    - `swiftblock snap featureflag`: Dynamic Feature Toggle Provider
    - `swiftblock snap deeplink`: Universal Link & URL Scheme Router
    - `swiftblock snap validator`: Form & Input Validation Engine
    - `swiftblock snap theme`: Design System Color & Style Engine
    - `swiftblock snap font`: Dynamic Typography Manager
    - `swiftblock snap formatting`: Currency, Date, and Number Formatters
    - `swiftblock snap media`: Image & Media Picker Helpers
    - `swiftblock snap permission`: Camera, Location, and Photo Permission Requester

    ---

    ## CLI Options & Usage Tips
    - **Dry Run**: Pass `--dry-run` to simulate generation without writing files to disk.
    - **Flavors**: Pass `--flavor <key>=<value>` for bricks with flavors (e.g. `swiftblock snap featureflag --flavor provider=in-memory`).
    - **Custom Variables**: Pass `--var <key>=<val>` for template variables (e.g. `swiftblock snap network --var timeout=30`).
    - **Diagnostics**: Run `swiftblock doctor` to verify environment and detect broken dependencies.
    """

    public static let rootAgentsMarkdown = """
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
    """

    public static let cursorRuleMarkdown = """
    ---
    description: SwiftBlock architectural scaffolding and brick generation guidelines
    globs: **/*.swift
    alwaysApply: true
    ---

    # SwiftBlock Rules

    - This project is managed by SwiftBlock CLI.
    - When creating new features, screens, or architectural layers, run `swiftblock snap <brick> <Name>` or `swiftblock kit add <kit> <Name>`.
    - Available feature bricks: `scene`, `usecase`, `repository`, `service`, `entity`, `coordinator`.
    - Available core bricks: `network`, `storage`, `keychain`, `auth`, `logger`, `config`, `featureflag`, `deeplink`.
    - Verify project health using `swiftblock doctor`.
    """

    public static let claudeMarkdown = """
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
    """

    public static let copilotMarkdown = """
    # SwiftBlock Instructions (GitHub Copilot)

    This repository uses **SwiftBlock** for modular scaffolding and architectural components.

    ## Scaffolding Instructions
    When assisting the developer in adding new features, views, services, or domain logic:
    - Recommend and use `swiftblock snap <brick> <Name>` or `swiftblock kit add clean-feature <Module>`.
    - Available generative bricks: `scene`, `usecase`, `repository`, `service`, `entity`, `coordinator`.
    - Available foundation singletons: `network`, `storage`, `keychain`, `auth`, `logger`, `config`.
    - Do not write repetitive boilerplate architecture files from scratch.
    """
}

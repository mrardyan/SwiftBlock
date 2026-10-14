# AI Agent Integration Guide

**SwiftBlock** is built from the ground up to be **AI Agent-Native**. With the `swiftblock agent setup` command, you can instantly turn any codebase into an AI-empowered development environment that instructs AI assistants (Google Antigravity, Anthropic Claude Code, Cursor, and GitHub Copilot) to scaffold architecture using SwiftBlock instead of writing manual boilerplate.

---

## 1. Quick Setup

Run `swiftblock agent setup` inside your project root:

```bash
cd MyProject
swiftblock agent setup
```

Output:
```
✔ Generated .agents/skills/swiftblock/SKILL.md
✔ Generated AGENTS.md
✔ Generated CLAUDE.md
✔ Generated .cursor/rules/swiftblock.mdc
✔ Generated .github/copilot-instructions.md
```

---

## 2. Supported AI Assistants

| Assistant | Embedded Configuration | Purpose |
|---|---|---|
| **Google Antigravity** | `.agents/skills/swiftblock/SKILL.md` | Eagerly loaded skill with CLI syntax, available bricks, and architectural workflows. |
| **Universal Agents** | `AGENTS.md` | Standard markdown rules detailing feature scaffolding conventions and commands. |
| **Claude Code** | `CLAUDE.md` | Concise developer cheat sheet and testing instructions for Claude Code sessions. |
| **Cursor IDE** | `.cursor/rules/swiftblock.mdc` | Contextual MDC rule matching Swift files to recommend `swiftblock snap` commands. |
| **GitHub Copilot** | `.github/copilot-instructions.md` | Repository guidelines instructing Copilot to reuse existing foundation bricks. |

---

## 3. Targeting Specific Assistants

You can filter which assistant files to generate using the `--target` flag:

```bash
# Generate only for Antigravity and Claude Code
swiftblock agent setup --target antigravity,claude

# Generate for all except Cursor
swiftblock agent setup --no-cursor
```

---

## 4. How It Works

Once embedded, whenever an AI assistant is asked to add a new feature (e.g. *"Create a Profile screen with networking and cache"*), the agent reads the guidelines and runs:

```bash
swiftblock snap network
swiftblock snap cache
swiftblock kit add clean-feature Profile
```

This prevents AI coding assistants from generating inconsistent, non-standard architecture from scratch.

---
paths:
  - "**/*.kt"
  - "**/*.java"
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.py"
  - "**/*.sh"
  - "**/*.zsh"
  - "**/*.kts"
  - "bin/**"
  - "hooks/**"
---

# Writing code

- **Tests for every change**, each able to fail for a real reason — the `writing-tests` skill.
- **Comments are a last resort:** a rename or an extracted function beats one, and only a non-obvious *why*
  survives — the `cutting-comments` skill.
- **Never use star imports**, expanding any you touch. **Hold every cause as a hypothesis** until you reproduce
  or measure it — the `proving-causes` skill.
- **Run the project's own formatters and linters** in their fixing form before handing over, found from its config
  (`package.json`, Gradle tasks, `.pre-commit-config.yaml`, `.husky/`, `biome.json`, `ruff.toml`). Never run one
  the project doesn't configure, and say so rather than silently skipping a broken one. Report pre-existing
  failures in code you didn't touch rather than fixing them, and don't let them block your own work; where the user
  owns the commit their hook is no substitute, so run the tools yourself or hand over a self-rewriting diff.

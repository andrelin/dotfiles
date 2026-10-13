---
paths:
  - "init/30_homebrew_helpers.sh"
  - "init/31_homebrew_recipes.sh"
  - "init/33_node_versions.sh"
  - "source/10_java.sh"
  - "source/11_node.sh"
  - "tips/12_project_workflow.md"
  - "tips/23_jvm.md"
---

# Installed Java and Node versions

One rule for both, computed on every `dotfiles` run, never a hand-kept list: the **two latest LTS lines plus the
latest release**, or three LTS lines while the latest release is itself an LTS. The **newest LTS is the default**.

- **Java** (`java_recipes` in `init/30_homebrew_helpers.sh`, used by `31_homebrew_recipes.sh`; default in
  `source/10_java.sh`): an LTS every fourth release from 17.
  Homebrew adds `openjdk@N` only once N is superseded, so the latest release is always plain `openjdk`; the
  recipes are worked out from the version `openjdk` is about to install, so a superseded LTS is never lost.
- **Node** (`init/33_node_versions.sh`): LTS lines come from `fnm list-remote`.
- Keep the version maths out of a fixed list: a change that hardcodes a version reintroduces the manual step.

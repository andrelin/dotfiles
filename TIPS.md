# Tips

A curated, growing index of terminal tricks, repo features, and bundled-tool basics. Read on GitHub, or run `tips` in a shell to print them.

> **Start here:** [Tip 20.1 — Working with the dotfiles repo](tips/20_shell_and_meta.md#tip-201-working-with-the-dotfiles-repo) — edit, reload, re-apply. The single most useful tip if you've cloned this repo and don't know where to begin.

Tips are split into category files under `tips/`. The leading two-digit prefix puts them in a meaningful "decade":

- `1x` — Terminal: general tricks + standalone CLI tools
- `2x` — Repo features (custom aliases, functions, scripts in this repo)
- `3x` — Zsh ecosystem
- `4x` — Infrastructure tooling (kubernetes, kafka — **optional installs**)
- `5x` — IDEs and editors
- `6x` — Web tools (bookmark-style references)

Numbering is `<FILE>.<N>`, e.g. Tip 22.3 lives in `tips/22_dev_infra.md`. The `tips` shell function takes the same selectors:

```
tips                  Print all tips
tips <FILE>           Print all tips in that file (e.g. tips 22)
tips <D>x             Print every file in a decade (e.g. tips 2x)
tips <FROM>-<TO>      Print every file in an explicit range (e.g. tips 20-24)
tips <FILE>.<N>       Print a single tip (e.g. tips 22.3)
tips -l [<sel>]       List titles only; selector is optional
tips -h               Help
```

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [1x — Terminal](#1x--terminal)
- [2x — Repo features](#2x--repo-features)
- [3x — Zsh ecosystem](#3x--zsh-ecosystem)
- [4x — Infrastructure tooling (optional)](#4x--infrastructure-tooling-optional)
- [5x — IDEs and editors](#5x--ides-and-editors)
- [6x — Web tools](#6x--web-tools)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## 1x — Terminal

- [10. Terminal](tips/10_terminal.md) — keyboard shortcuts, history expansion, background jobs, clipboard piping
- [11. Text tools](tips/11_text_tools.md) — jq, fzf, ag
- [12. Project workflow CLIs](tips/12_project_workflow.md) — gh, git-secret, direnv, nvm

## 2x — Repo features

- [20. Shell & repo workflow](tips/20_shell_and_meta.md) — `dot`, `reload`, `dotfiles`, file/dir helpers, `q` editor, `eachdir`, `isip`
- [21. Git](tips/21_git.md) — workflow helpers, repo diagnostics
- [22. Local dev infra](tips/22_dev_infra.md) — docker, kubernetes (`kdel*`), kafka, throwaway Postgres
- [23. JVM](tips/23_jvm.md) — `jdk` switching, Maven OpenRewrite recipes
- [24. Claude Code integration](tips/24_claude_code.md) — `sync-claude-deny`, `sort-claude-settings`, pre-commit automation

## 3x — Zsh ecosystem

- [30. zsh](tips/30_zsh.md) — oh-my-zsh + vendor plugins (autosuggestions, syntax-highlighting, completions)

## 4x — Infrastructure tooling (optional)

- [40. Kubernetes CLI](tips/40_kubernetes_cli.md) — kubectl, kubectx, kube-ps1, k9s
- [41. Kafka CLI](tips/41_kafka_cli.md) — topics, console consumer, console producer

## 5x — IDEs and editors

- [50. IntelliJ IDEA](tips/50_intellij.md) — semantic highlighting, Rainbow Brackets, Key Promoter X, Search Everywhere, Recent Files
- [51. Sublime Text](tips/51_sublime_text.md) — Package Control, `q`/`qq` snippets

## 6x — Web tools

- [60. Web tools](tips/60_web_tools.md) — Debuggex, Monkeytype, Kafka Streams Topology Visualiser

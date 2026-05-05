<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Zsh Ecosystem](#zsh-ecosystem)
  - [Tip 30.1: oh-my-zsh](#tip-301-oh-my-zsh)
    - [Per-tool plugins](#per-tool-plugins)
    - [General shell utilities](#general-shell-utilities)
  - [Tip 30.2: zsh-autosuggestions](#tip-302-zsh-autosuggestions)
  - [Tip 30.3: zsh-syntax-highlighting](#tip-303-zsh-syntax-highlighting)
  - [Tip 30.4: zsh-completions](#tip-304-zsh-completions)
  - [Tip 30.5: zsh-history-substring-search](#tip-305-zsh-history-substring-search)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Zsh Ecosystem

The zsh framework (oh-my-zsh) and the vendored zsh plugins this repo ships with.

## Tip 30.1: oh-my-zsh

Loads the `andrelin` theme plus the plugin set in [`source/90_oh-my-zsh.zsh`](../source/90_oh-my-zsh.zsh) — that file is the source of truth.

Highest-leverage shortcuts:

```sh
z foo                       # cd to most-used dir matching "foo" (z plugin)
Esc Esc                     # prepend "sudo " to the current command (sudo plugin)
web-search google "query"   # open a search in your browser (web-search plugin)
```

Enabled plugins, grouped to make the list scannable. Each name links to its upstream docs.

### Per-tool plugins

Aliases and/or tab-completion for one specific CLI. Skip the rows whose tool you don't use.

| Plugin | Key aliases / commands |
| --- | --- |
| [1password](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/1password) | `opswitch` (switch account), `opurl <item>` (open URL). Needs the `op` CLI — bundled with the 1Password desktop app on macOS. |
| [brew](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/brew) | Completions only — `brew`, `brew cask`, `brew services`. |
| [docker](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/docker) | Completions + `dbl` (build), `drm` (rm), `drmi` (rmi), `dst` (stats). |
| [docker-compose](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/docker-compose) | `dco` (compose), `dcup`/`dcupd` (up / up -d), `dcdn` (down), `dcl`/`dclf` (logs / logs -f), `dcb` (build), `dce` (exec), `dcps` (ps), `dcrun` (run). |
| [gh](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/gh) | Completions only — pulled from `gh completion -s zsh` and cached. Pairs with Tip 12.1. |
| [git](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git) | Massive alias set. Daily drivers: `gst`, `gco`, `gcm` (checkout main), `gcb` (checkout -b), `gp`, `gl`, `gca`, `glola` (pretty graph log). |
| [git-extras](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git-extras) | Completions for [git-extras](https://github.com/tj/git-extras) commands (`git delete-branch`, `git changelog`, `git ignore`, …). |
| [gradle](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/gradle) | Completion for Gradle tasks in the current project's `build.gradle`. `gw` (gradle wrapper). |
| [kubectl](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/kubectl) | `k`, `kgp` (get pods), `kgs` (svc), `kgd` (deployments), `kdp <pod>` (describe), `kl <pod>` (logs), `keti <pod> bash` (exec interactive). |
| [mvn](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/mvn) | `mci` (clean install), `mcp` (clean package), `mt` (test), `mvn-color` (colourised wrapper). |
| [npm](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/npm) | `npmg` (global), `npmS`/`npmD` (install --save / --save-dev), `npmO` (outdated), `npmL` (list --depth=0). |
| [pip](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/pip) | Completions sourced from PyPI's package list (cached). `pip-update` upgrades everything installed. |
| [python](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/python) | `mkv` (mkvirtualenv), `vrun` (workon), `pyfind` (find `.py`), `pyclean [path]` (remove `__pycache__`, `.pyc`/`.pyo`, `.mypy_cache`, `.pytest_cache`). |
| [sublime](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/sublime) | `st <file>` (open file), `st .` (open cwd as project), `stt` (open cwd in new window). |

### General shell utilities

Don't tie to one tool — useful in any shell session.

| Plugin | What it does |
| --- | --- |
| [alias-finder](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/alias-finder) | Prints any matching alias when you type a long command (`alias-finder "git status"` → `gst`). Helps internalise the alias surface. |
| [colored-man-pages](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/colored-man-pages) | Colourises `man` output. Automatic — no commands. |
| [colorize](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/colorize) | Syntax-highlighted file viewing via Pygments / chroma. `ccat file.py`, `cless file.py`. |
| [command-not-found](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/command-not-found) | On Ubuntu/WSL, suggests the apt package for a missing command. No-op on macOS. |
| [encode64](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/encode64) | `encode64 "hello"`, `decode64 "aGVsbG8="`. Handy for JWTs (split on `.`, decode each segment) and basic-auth tokens. |
| [extract](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/extract) | `extract <archive>` for any common format (tar variants, zip, 7z, xz, zst, lz, rpm, deb, …). Overrides the narrower `extract()` in `source/40_functions.sh`, which stays as a fallback. |
| [macos](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/macos) (macOS only) | Finder/iTerm helpers: `tab`, `ofd` (open Finder here), `cdf` (cd to Finder), `quick-look <file>`, `pfd` (path of frontmost Finder). |
| [safe-paste](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/safe-paste) | Stops pasted text from auto-executing if it contains a newline. Defends against malicious clipboard snippets. Zero-config. |
| [sudo](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/sudo) | `Esc Esc` toggles `sudo` on the current line (or prepends to the previous command if the line is empty). |
| [urltools](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/urltools) | `urlencode "a b&c"`, `urldecode "a%20b%26c"`. Pair with `encode64` for HTTP/OAuth poking. |
| [web-search](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/web-search) | `google "query"`, `ddg "query"`, `bing "query"`, `github "query"`, `stackoverflow "query"`, … |
| [z](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/z) | Frecency-based directory jumping. `z foo` cd's to the most-used dir matching "foo"; `z -l foo` lists candidates. |

Full plugin index (for adding new ones): <https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins>

## Tip 30.2: zsh-autosuggestions

As you type, suggests completions in grey based on history. Press `→` (right arrow) or `End` to accept.

```
git che█eckout main      # ← type "git che", grey suggestion shows "ckout main"
```

Sourced from `vendor/zsh-autosuggestions/`. Repo: <https://github.com/zsh-users/zsh-autosuggestions>

## Tip 30.3: zsh-syntax-highlighting

Real-time colouring of commands as you type. Valid commands turn green, invalid red, strings get their own colour. No commands to learn — it just works.

Repo: <https://github.com/zsh-users/zsh-syntax-highlighting>

## Tip 30.4: zsh-completions

Extra `Tab`-completion definitions for many CLI tools beyond zsh's built-ins. Activates automatically; press `Tab` and feel the difference.

Repo: <https://github.com/zsh-users/zsh-completions>

## Tip 30.5: zsh-history-substring-search

Type a partial command, hit `↑` to walk through every history entry containing that substring (and `↓` to walk back). Faster than `Ctrl+R` for "I ran something with `kubectl logs` last week" recall.

```
kubectl logs█       # ← type prefix, then ↑ to cycle through matching history
```

Vendored separately (not via omz) because it must load **after** `zsh-syntax-highlighting`, while omz plugins all load earlier in `source/90_oh-my-zsh.zsh`. See the load order in `source/99_zsh-modules.zsh`.

Repo: <https://github.com/zsh-users/zsh-history-substring-search>

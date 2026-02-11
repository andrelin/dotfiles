# Init Scripts

Run once during `dotfiles` setup. Numbered by dependency order:

| Range | Category              | Examples                  |
|-------|-----------------------|---------------------------|
| 10–19 | System prerequisites  | SSH, Xcode, git hooks     |
| 20–29 | Package manager       | Homebrew                  |
| 30–39 | Package installation  | Formulae, casks           |
| 40–49 | Shell setup           | Zsh                       |
| 50–59 | App configuration     | IntelliJ, Sublime Text    |

Filename conventions:
- `_macos_`, `_linux_`, `_wsl_`, `_ubuntu_`, `_rhel_` — auto-deselected on other platforms
- `_personal_` — default unchecked (must be explicitly selected)

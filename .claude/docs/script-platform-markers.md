# Platform markers in `init/` and `source/` filenames

The convention is in `.claude/rules/scripts.md`; this is the table.

| Marker | Auto-deselected on |
| --- | --- |
| `_macos_` | non-macOS |
| `_linux_` | non-Linux (Ubuntu, RHEL) |
| `_ubuntu_`, `_ubuntu_desktop_`, `_rhel_` | anything but that distro |
| `_wsl_` | non-WSL |
| `_personal_` | nothing — it only defaults to unchecked |

The marker names are exactly the `is_*` checks `get_os` iterates in `bin/dotfiles`.

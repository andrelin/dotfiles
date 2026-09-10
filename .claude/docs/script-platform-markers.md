# Platform markers in `init/` filenames

The convention is in `.claude/rules/scripts.md`; this is the table.
Markers work only in `init/`, where `init_files()` reads them — `src()` sources every `source/*sh` file
unconditionally, so a marker in a `source/` filename is decoration.

| Marker | Auto-deselected on |
| --- | --- |
| `_macos_` | non-macOS |
| `_linux_` | non-Linux (Ubuntu, RHEL) |
| `_ubuntu_`, `_ubuntu_desktop_`, `_rhel_` | anything but that distro |
| `_wsl_` | non-WSL |
| `_personal_` | nothing — it only defaults to unchecked |

The platform markers are the `is_*` checks `get_os` iterates in `bin/dotfiles`.
`_personal_` is not one of them — nothing deselects it by platform; it only starts unchecked.

**`_linux_` is not deselected on WSL.** `is_linux()` is `is_ubuntu || is_rhel`, and `is_ubuntu` greps
`/etc/issue`, which says Ubuntu on WSL-Ubuntu. So a `_linux_` script stays selected there.
Use `_wsl_` for WSL-only work, and a code guard where it actually matters.

<!-- DOCTOC SKIP -->

# Shell and Repo Workflow

Working with the dotfiles repo itself, plus general shell utilities shipped by this repo.

## Tip 20.1: Working with the Dotfiles Repo

The on-ramp tip — everything else assumes you can edit, reload, and re-apply this repo.

```sh
dot           # cd ~/.dotfiles
qs            # open the repo in $EDITOR
qv            # open ~/.vimrc in $EDITOR (use 'qs' to roam from there)
reload        # re-source ~/.zshrc / ~/.bashrc after editing source/*.sh
dotfiles      # re-run init scripts (apply new copy/link entries, install new homebrew/cask/flatpak entries)
```

Typical loop: edit a file in `source/`, run `reload`, the new alias/function is live. For changes to `copy/`, `link/`, or `init/`, run `dotfiles` to apply them. From `source/30_aliases.sh`, `source/22_editor.sh`, `bin/dotfiles`.

## Tip 20.2: File and Directory Helpers

```sh
mkcd path/to/dir       # mkdir -p + cd into it
cl path                # cd + ls -la
extract foo.tar.gz     # auto-detect archive type, unpack
extract foo.zip
dict word              # search the system dictionary (uses `ag`)
```

From `source/40_functions.sh`. For Python cache cleanup, the omz `python` plugin's `pyclean` is preferred — see Tip 30.1.

## Tip 20.3: The `q` Editor Shortcut

Open files in `$EDITOR`, or pipe stdin into vim.

```sh
q some-file.txt              # open in $EDITOR
q file1 file2 file3          # multiple files
ps aux | q                   # pipe stdin into vim (a stand-in for clipboard editing)
```

The `:q` muscle-memory alias also exits the shell. From `source/22_editor.sh`.

## Tip 20.4: `eachdir` — Run a Command Across Many Directories

Useful when you have a parent dir full of repos and want to run something in each.

```sh
cd ~/src
eachdir 'git status -s'             # quick repo overview
eachdir 'git pull --rebase'         # update everything
eachdir 'mvn test' repo-* repo2-*   # filter to matching subdirs
```

`eachdir` is sourced (via the `eachdir` alias) so it can use your shell aliases and functions inside the wrapped command. From `bin/eachdir`.

## Tip 20.5: `isip` — Check Bound IP Addresses

```sh
isip                  # list all IPs bound to local interfaces
isip 192.168.1.42     # exit 0 if that IP is bound, non-zero otherwise
```

Handy for scripts that need to wait for a VPN or detect a particular network. From `bin/isip`.

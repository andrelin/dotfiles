<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Installation](#installation)
  - [macOS Notes](#macos-notes)
  - [Ubuntu / WSL Notes](#ubuntu--wsl-notes)
  - [Heed this critically important warning before you install](#heed-this-critically-important-warning-before-you-install)
  - [Actual installation](#actual-installation)
    - [Ubuntu / WSL](#ubuntu--wsl)
    - [macOS](#macos)
  - [Actual installation (for me)](#actual-installation-for-me)
    - [Ubuntu / WSL](#ubuntu--wsl-1)
    - [macOS](#macos-1)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Installation

## macOS Notes

You need to have [XCode](https://developer.apple.com/download/?=xcode) or, at the very minimum,
the [XCode Command Line Tools](https://developer.apple.com/download/?=command%20line%20tools),
which are available as a much smaller download.

The easiest way to install the XCode Command Line Tools is to open up a terminal, type `xcode-select --install` and follow the prompts.

## Ubuntu / WSL Notes

You should at least update/upgrade APT with `sudo apt-get -qq update && sudo apt-get -qq dist-upgrade` first.

## Heed this critically important warning before you install

**If you're not me, please _do not_ install dotfiles directly from this repo!**

Why? Because I often completely break this repo while updating.
Which means that if I do that and you run the `dotfiles` command, your home directory will burst into flames,
and you'll have to go buy a new computer. No, not really, but it will be very messy.

## Actual installation

1. [Read my gently-worded note](#heed-this-critically-important-warning-before-you-install)
1. Fork this repo
1. Open a terminal/shell and do this (change `andrelin` and `main` as appropriate):

### Ubuntu / WSL

```sh
export DOTFILES_GH_USER=andrelin
export DOTFILES_GH_BRANCH=main
bash -c "$(wget -qO- https://raw.github.com/$DOTFILES_GH_USER/dotfiles/$DOTFILES_GH_BRANCH/bin/dotfiles)" && source ~/.zshrc
```

### macOS

```sh
export DOTFILES_GH_USER=andrelin
export DOTFILES_GH_BRANCH=main
bash -c "$(curl -fsSL https://raw.github.com/$DOTFILES_GH_USER/dotfiles/$DOTFILES_GH_BRANCH/bin/dotfiles)" && source ~/.zshrc
```

Since you'll be using the [dotfiles][dotfiles] command on subsequent runs, you'll only have to set the
`DOTFILES_GH_USER` variable for the initial install, but if you have a custom branch, you _will_ need to export
`DOTFILES_GH_BRANCH` for subsequent runs.

There's a lot of stuff that requires admin access via `sudo`, so be warned that you might need to enter your password here or there.

## Actual installation (for me)

### Ubuntu / WSL

```sh
bash -c "$(wget -qO- https://raw.github.com/andrelin/dotfiles/main/bin/dotfiles)" && source ~/.zshrc
```

### macOS

```sh
bash -c "$(curl -fsSL https://raw.github.com/andrelin/dotfiles/main/bin/dotfiles)" && source ~/.zshrc
```

[dotfiles]: ../bin/dotfiles

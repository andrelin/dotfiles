<!-- DOCTOC SKIP -->

# Terminal

General terminal tricks. Tips for specific CLI tools live in adjacent files (`11_text_tools.md`, `12_project_workflow.md`).

## Tip 10.1: Keyboard Shortcuts You're Probably Ignoring

Line editing without the arrow keys.

```
Ctrl + A     Jump to beginning of line
Ctrl + E     Jump to end of line
Ctrl + W     Delete one word backward
Ctrl + U     Clear everything before cursor
Ctrl + K     Clear everything after cursor
Ctrl + L     Clear the screen (same as 'clear')
Ctrl + C     Cancel current command
Ctrl + Z     Suspend current process (resume with 'fg')
Alt  + F     Jump forward one word
Alt  + B     Jump backward one word
```

Most useful combos: `Ctrl+A` then `Ctrl+K` to wipe a line. `Alt+F` / `Alt+B` to hop word-by-word in long commands.

## Tip 10.2: History Expansion

Reuse pieces of previous commands without retyping or arrowing up.

```
!!              Repeat the last command
sudo !!         Repeat last command with sudo
!$              Last argument of previous command
!^              First argument of previous command
!*              All arguments of previous command
!vim            Repeat last command starting with 'vim'
!vim:p          Print it without running (then up-arrow to edit)
^old^new        Re-run last command, replacing 'old' with 'new'
!!:gs/old/new   Re-run with all occurrences replaced
```

`^chekcout^checkout` fixes a typo in the previous command. `!$` is gold after a long path: `touch /etc/nginx/sites-available/foo.conf` then `vim !$`.

## Tip 10.3: Run Things in Background

Append `&` to send a command to the background — terminal frees up immediately.

```sh
npm run build &
```

You'll see `[1] 23456` (job ID and PID).

Commands:

```
jobs            List background jobs
fg              Bring most recent job to foreground
fg %1           Bring job 1 to foreground
bg              Resume a suspended job in background
```

Shortcut:

```
Ctrl + Z        Suspend the current foreground job
```

Forgot the `&`? `Ctrl+Z` to suspend, then `bg` to keep it running in the background.

## Tip 10.4: Pipe to the Clipboard

Skip the mouse — pipe command output straight into the clipboard.

```sh
# macOS
cat some-file.txt | pbcopy

# Linux (X11)
cat some-file.txt | xclip -selection clipboard
```

Common uses:

```sh
cat ~/.ssh/id_rsa.pub | pbcopy        # copy SSH public key
git rev-parse HEAD | pbcopy           # copy current commit SHA
echo "$LONG_TOKEN" | pbcopy           # copy a long string
```

Reverse direction: `pbpaste` (macOS) or `xclip -o -selection clipboard` (Linux).

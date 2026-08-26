<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [IntelliJ IDEA — configuration](#intellij-idea--configuration)
  - [Visuals & readability](#visuals--readability)
    - [Tip 50.1: Enable Semantic Highlighting](#tip-501-enable-semantic-highlighting)
    - [Tip 50.2: Rainbow Brackets Plugin](#tip-502-rainbow-brackets-plugin)
    - [Tip 50.3: Make Errors Stand Out](#tip-503-make-errors-stand-out)
    - [Tip 50.4: Make Comments Visible](#tip-504-make-comments-visible)
  - [Setup & customisation](#setup--customisation)
    - [Tip 50.5: Auto-Import on the Fly](#tip-505-auto-import-on-the-fly)
    - [Tip 50.6: Tame the Intention Bulb](#tip-506-tame-the-intention-bulb)
    - [Tip 50.7: Key Promoter X Plugin](#tip-507-key-promoter-x-plugin)
    - [Tip 50.8: .ignore Plugin](#tip-508-ignore-plugin)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# IntelliJ IDEA — configuration

How IntelliJ is set up and made readable.
The shipped settings (codestyles, keymaps, color schemes) live in `conf/intellij/` and are linked into IntelliJ's
config dir by `init/50_macos_intellij.sh`.
Day-to-day usage tips are in [51. IntelliJ IDEA — usage](51_intellij_usage.md).

Shortcuts below are from the default IntelliJ **macOS keymap**; Linux/WSL equivalents are shown in
parentheses where they differ.
The mapping isn't always `Cmd → Ctrl` (e.g. *Type Hierarchy* uses `Ctrl + H` on both, *Go to Class* is
`Cmd + O` on macOS but `Ctrl + N` on Linux).
If a binding doesn't fire, look it up with **`Cmd + Shift + A` → Find Action**.

## Visuals & readability

Use colour to surface the things that matter — variables, brackets, errors, comments.

### Tip 50.1: Enable Semantic Highlighting

Different colours per local variable / parameter — makes data flow visible at a glance.

> Settings → Editor → Color Scheme → Language Defaults → check **Semantic highlighting**.

Particularly useful in long methods or unfamiliar code.

### Tip 50.2: Rainbow Brackets Plugin

Colour-codes matched brackets/parens so nested structures are instantly readable. Big win in Kotlin/Java with deeply nested lambdas.

> Settings → Plugins → search "Rainbow Brackets" → install → restart.

Plugin: <https://plugins.jetbrains.com/plugin/10080-rainbow-brackets>

### Tip 50.3: Make Errors Stand Out

Tiny red squiggles are easy to miss in dense code. Give errors a background colour so they jump out.

> Settings → Editor → Color Scheme → General → Errors and Warnings → **Error** → set **Background** (e.g. `#630202`).

Same trick works for Warnings, deprecation, and unused-symbol if you want to dial up their visibility.

### Tip 50.4: Make Comments Visible

Defaults render comments in low-contrast italic grey — they fade into the background. Comments are written for humans; bump the contrast.

> Settings → Editor → Color Scheme → Language Defaults → Comments → Line / Block / Doc comment → raise Foreground contrast (or check **Bold**).

## Setup & customisation

One-time tweaks: behaviour settings and plugins worth installing.

### Tip 50.5: Auto-Import on the Fly

Stop importing manually. IntelliJ adds unique imports as you type and removes unused ones on save.

> Settings → Editor → General → Auto Import →
>
> - check **Add unambiguous imports on the fly**
> - check **Optimize imports on the fly**

### Tip 50.6: Tame the Intention Bulb

The lightbulb hint pop-up gets noisy. Disable individual intentions or the bulb itself.

> Settings → Editor → Intentions → uncheck specific intentions, or turn off "Show intention bulb" entirely.

### Tip 50.7: Key Promoter X Plugin

Pop-up nag whenever you click a menu item that has a keyboard shortcut. Best way to actually learn IntelliJ's shortcuts.

> Settings → Plugins → search "Key Promoter X" → install → restart.

Plugin: <https://plugins.jetbrains.com/plugin/9792-key-promoter-x>

### Tip 50.8: .ignore Plugin

Adds syntax highlighting, templates, and a generator for `.gitignore`, `.dockerignore`, `.eslintignore`, and a dozen others.

> Settings → Plugins → search ".ignore" → install → restart.

Plugin: <https://plugins.jetbrains.com/plugin/7495--ignore>

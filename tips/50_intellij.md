<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [IntelliJ IDEA](#intellij-idea)
  - [Visuals & readability](#visuals--readability)
    - [Tip 50.1: Enable Semantic Highlighting](#tip-501-enable-semantic-highlighting)
    - [Tip 50.2: Rainbow Brackets Plugin](#tip-502-rainbow-brackets-plugin)
    - [Tip 50.3: Make Errors Stand Out](#tip-503-make-errors-stand-out)
    - [Tip 50.4: Make Comments Visible](#tip-504-make-comments-visible)
  - [Search & navigation](#search--navigation)
    - [Tip 50.5: Search Everywhere & Find Action](#tip-505-search-everywhere--find-action)
    - [Tip 50.6: Recent Files & Recent Locations](#tip-506-recent-files--recent-locations)
    - [Tip 50.7: Direct-Path Navigation](#tip-507-direct-path-navigation)
    - [Tip 50.8: Hierarchy & Inline Docs](#tip-508-hierarchy--inline-docs)
  - [Editing & refactoring](#editing--refactoring)
    - [Tip 50.9: Refactor: Extract Anything](#tip-509-refactor-extract-anything)
    - [Tip 50.10: Paste from History](#tip-5010-paste-from-history)
  - [Build & debugging](#build--debugging)
    - [Tip 50.11: Analyze Stack Trace](#tip-5011-analyze-stack-trace)
    - [Tip 50.12: Add Dependencies from Build Files](#tip-5012-add-dependencies-from-build-files)
  - [Setup & customisation](#setup--customisation)
    - [Tip 50.13: Auto-Import on the Fly](#tip-5013-auto-import-on-the-fly)
    - [Tip 50.14: Tame the Intention Bulb](#tip-5014-tame-the-intention-bulb)
    - [Tip 50.15: Key Promoter X Plugin](#tip-5015-key-promoter-x-plugin)
    - [Tip 50.16: .ignore Plugin](#tip-5016-ignore-plugin)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# IntelliJ IDEA

Productivity tips for IntelliJ. The shipped settings (codestyles, keymaps, color schemes) live in `conf/intellij/` and are linked into IntelliJ's config dir by `init/50_macos_intellij.sh`.

Shortcuts below are from the default IntelliJ **macOS keymap**; Linux/WSL equivalents are shown in parentheses where they differ. The mapping isn't always `Cmd → Ctrl` (e.g. *Type Hierarchy* uses `Ctrl + H` on both, *Go to Class* is `Cmd + O` on macOS but `Ctrl + N` on Linux). If a binding doesn't fire, look it up with **`Cmd + Shift + A` → Find Action**.

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

## Search & navigation

Move around code without the mouse.

### Tip 50.5: Search Everywhere & Find Action

```
Double Shift             Search Everywhere — files, classes, symbols, settings, recent
Cmd + Shift + A          Find Action — invoke any IDE command by name
```

Find Action is the universal escape hatch — when you don't know the shortcut, ask for the action.

### Tip 50.6: Recent Files & Recent Locations

```
Cmd + E                  Recent Files
Cmd + Shift + E          Recent Locations (recently visited code positions, with a preview)
```

Recent Locations is underrated — much better than `Cmd+E` when you remember "I saw this code somewhere five minutes ago" but not the file name.

### Tip 50.7: Direct-Path Navigation

`Cmd + Shift + A` / Double Shift are universal but slower. These jump directly:

```
Cmd + O                  Go to class                   (Linux/WSL: Ctrl + N)
Cmd + Shift + O          Go to file                    (Linux/WSL: Ctrl + Shift + N)
Cmd + F12                File structure popup (methods/fields in current file)
Alt + F1                 Reveal current file/symbol in Project view (or any other tool window)
Cmd + [ / Cmd + ]        Navigate back / forward       (Linux/WSL: Ctrl + Alt + Left/Right)
Cmd + Shift + T          Jump to (or create) the test class for the current class
```

### Tip 50.8: Hierarchy & Inline Docs

```
Ctrl + H                 Type hierarchy (parents/subclasses of the current type)
Ctrl + Alt + H           Call hierarchy (callers of the current method)
Alt + Space              Quick definition popup        (Linux/WSL: Ctrl + Shift + I)
F1                       Quick documentation (Javadoc) (Linux/WSL: Ctrl + Q)
```

Quick Definition is the one — peek at a function's body without losing your place. Note: `Ctrl` (not `Cmd`) on macOS for the hierarchy actions; `Cmd+H` would hide the IDE.

## Editing & refactoring

Change code with the keyboard, not the mouse.

### Tip 50.9: Refactor: Extract Anything

```
Cmd + Alt + M            Extract method
Cmd + Alt + V            Extract variable
Cmd + Alt + F            Extract field
Cmd + Alt + C            Extract constant
Cmd + Alt + P            Extract parameter
```

Select an expression first, then hit the extract you want — IntelliJ infers the type and offers naming.

### Tip 50.10: Paste from History

```
Cmd + Shift + V          Paste from clipboard history (last ~5 entries)
```

Saves you when you copied something else over the thing you actually needed.

## Build & debugging

Tools for the workflow around your code, not in it.

### Tip 50.11: Analyze Stack Trace

Paste a stack trace from anywhere (k8s logs, Jenkins, terminal) and IntelliJ formats it with clickable file/line links.

> Analyze → Analyze Stack Trace → paste → OK.

To make it automatic on copy, tick **Automatically detect and analyze thread dumps copied to the clipboard outside the IDE** in the same dialog. After that, copying a stack trace anywhere and switching to IntelliJ pops up the formatted view.

### Tip 50.12: Add Dependencies from Build Files

Skip the search-on-Maven-Central detour — IntelliJ pulls coordinates from the local index.

```
Cmd + N (Alt + Insert on Linux/WSL)    Cursor inside <dependencies> in pom.xml, or
                                       inside dependencies { } in build.gradle / build.gradle.kts
```

Type a name → fuzzy-search Maven Central → pick a version. For Gradle, IntelliJ inserts the right `implementation "group:artifact:version"` line; for Maven, the full `<dependency>` block.

If your cursor isn't inside `dependencies { }` (or the popup doesn't show "Add Maven artifact dependency"), use **File → Project Structure → Modules → Dependencies → + → Library → From Maven** — works for either build system.

Same `Cmd + N` / `Alt + Insert` shortcut also generates getters/setters/constructors/`toString` inside Java classes.

## Setup & customisation

One-time tweaks: behaviour settings and plugins worth installing.

### Tip 50.13: Auto-Import on the Fly

Stop importing manually. IntelliJ adds unique imports as you type and removes unused ones on save.

> Settings → Editor → General → Auto Import →
>
> - check **Add unambiguous imports on the fly**
> - check **Optimize imports on the fly**

### Tip 50.14: Tame the Intention Bulb

The lightbulb hint pop-up gets noisy. Disable individual intentions or the bulb itself.

> Settings → Editor → Intentions → uncheck specific intentions, or turn off "Show intention bulb" entirely.

### Tip 50.15: Key Promoter X Plugin

Pop-up nag whenever you click a menu item that has a keyboard shortcut. Best way to actually learn IntelliJ's shortcuts.

> Settings → Plugins → search "Key Promoter X" → install → restart.

Plugin: <https://plugins.jetbrains.com/plugin/9792-key-promoter-x>

### Tip 50.16: .ignore Plugin

Adds syntax highlighting, templates, and a generator for `.gitignore`, `.dockerignore`, `.eslintignore`, and a dozen others.

> Settings → Plugins → search ".ignore" → install → restart.

Plugin: <https://plugins.jetbrains.com/plugin/7495--ignore>

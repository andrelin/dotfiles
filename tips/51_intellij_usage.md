<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [IntelliJ IDEA — usage](#intellij-idea--usage)
  - [Search & navigation](#search--navigation)
    - [Tip 51.1: Search Everywhere & Find Action](#tip-511-search-everywhere--find-action)
    - [Tip 51.2: Recent Files & Recent Locations](#tip-512-recent-files--recent-locations)
    - [Tip 51.3: Direct-Path Navigation](#tip-513-direct-path-navigation)
    - [Tip 51.4: Hierarchy & Inline Docs](#tip-514-hierarchy--inline-docs)
  - [Editing & refactoring](#editing--refactoring)
    - [Tip 51.5: Refactor: Extract Anything](#tip-515-refactor-extract-anything)
    - [Tip 51.6: Paste from History](#tip-516-paste-from-history)
  - [Build & debugging](#build--debugging)
    - [Tip 51.7: Analyze Stack Trace](#tip-517-analyze-stack-trace)
    - [Tip 51.8: Add Dependencies from Build Files](#tip-518-add-dependencies-from-build-files)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# IntelliJ IDEA — usage

Navigating, editing and debugging day to day.
Setup and appearance tips are in [50. IntelliJ IDEA — configuration](50_intellij_config.md).

Shortcuts below are from the default IntelliJ **macOS keymap**; Linux/WSL equivalents are shown in
parentheses where they differ.
The mapping isn't always `Cmd → Ctrl` (e.g. *Type Hierarchy* uses `Ctrl + H` on both, *Go to Class* is
`Cmd + O` on macOS but `Ctrl + N` on Linux).
If a binding doesn't fire, look it up with **`Cmd + Shift + A` → Find Action**.

## Search & navigation

Move around code without the mouse.

### Tip 51.1: Search Everywhere & Find Action

```
Double Shift             Search Everywhere — files, classes, symbols, settings, recent
Cmd + Shift + A          Find Action — invoke any IDE command by name
```

Find Action is the universal escape hatch — when you don't know the shortcut, ask for the action.

### Tip 51.2: Recent Files & Recent Locations

```
Cmd + E                  Recent Files
Cmd + Shift + E          Recent Locations (recently visited code positions, with a preview)
```

Recent Locations is underrated — much better than `Cmd+E` when you remember "I saw this code somewhere five minutes ago" but not the file name.

### Tip 51.3: Direct-Path Navigation

`Cmd + Shift + A` / Double Shift are universal but slower. These jump directly:

```
Cmd + O                  Go to class                   (Linux/WSL: Ctrl + N)
Cmd + Shift + O          Go to file                    (Linux/WSL: Ctrl + Shift + N)
Cmd + F12                File structure popup (methods/fields in current file)
Alt + F1                 Reveal current file/symbol in Project view (or any other tool window)
Cmd + [ / Cmd + ]        Navigate back / forward       (Linux/WSL: Ctrl + Alt + Left/Right)
Cmd + Shift + T          Jump to (or create) the test class for the current class
```

### Tip 51.4: Hierarchy & Inline Docs

```
Ctrl + H                 Type hierarchy (parents/subclasses of the current type)
Ctrl + Alt + H           Call hierarchy (callers of the current method)
Alt + Space              Quick definition popup        (Linux/WSL: Ctrl + Shift + I)
F1                       Quick documentation (Javadoc) (Linux/WSL: Ctrl + Q)
```

Quick Definition is the one — peek at a function's body without losing your place. Note: `Ctrl` (not `Cmd`) on macOS for the hierarchy actions; `Cmd+H` would hide the IDE.

## Editing & refactoring

Change code with the keyboard, not the mouse.

### Tip 51.5: Refactor: Extract Anything

```
Cmd + Alt + M            Extract method
Cmd + Alt + V            Extract variable
Cmd + Alt + F            Extract field
Cmd + Alt + C            Extract constant
Cmd + Alt + P            Extract parameter
```

Select an expression first, then hit the extract you want — IntelliJ infers the type and offers naming.

### Tip 51.6: Paste from History

```
Cmd + Shift + V          Paste from clipboard history (last ~5 entries)
```

Saves you when you copied something else over the thing you actually needed.

## Build & debugging

Tools for the workflow around your code, not in it.

### Tip 51.7: Analyze Stack Trace

Paste a stack trace from anywhere (k8s logs, Jenkins, terminal) and IntelliJ formats it with clickable file/line links.

> Analyze → Analyze Stack Trace → paste → OK.

To make it automatic on copy, tick **Automatically detect and analyze thread dumps copied to the clipboard outside the IDE** in the same dialog. After that, copying a stack trace anywhere and switching to IntelliJ pops up the formatted view.

### Tip 51.8: Add Dependencies from Build Files

Skip the search-on-Maven-Central detour — IntelliJ pulls coordinates from the local index.

```
Cmd + N (Alt + Insert on Linux/WSL)    Cursor inside <dependencies> in pom.xml, or
                                       inside dependencies { } in build.gradle / build.gradle.kts
```

Type a name → fuzzy-search Maven Central → pick a version. For Gradle, IntelliJ inserts the right `implementation "group:artifact:version"` line; for Maven, the full `<dependency>` block.

If your cursor isn't inside `dependencies { }` (or the popup doesn't show "Add Maven artifact dependency"), use **File → Project Structure → Modules → Dependencies → + → Library → From Maven** — works for either build system.

Same `Cmd + N` / `Alt + Insert` shortcut also generates getters/setters/constructors/`toString` inside Java classes.

---
paths:
  - "init/31_homebrew_recipes.sh"
  - "source/10_java.sh"
  - "tips/23_jvm.md"
---

# Installed JDK versions

Always three JDKs: the **two latest LTS releases** as `openjdk@N`, plus the **latest release** as plain `openjdk`.

- **A new LTS ships** (every two years in September: 21, 25, 29…): add `openjdk@N`. It is also the latest, so
  three LTS versions stay installed until the next non-LTS release.
- **A non-LTS ships** (every March and September): drop the oldest `openjdk@N`, back to two LTS plus latest.
- **Update in the same commit:** the recipes list in `init/31_homebrew_recipes.sh`, the default `JAVA_HOME`
  and the `jdk` usage comment in `source/10_java.sh`, and Tip 23.1 in `tips/23_jvm.md`.

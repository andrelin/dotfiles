<!-- DOCTOC SKIP -->

# JVM

JVM-related helpers shipped by this repo — JDK switching and Maven OpenRewrite recipe runners.

## Tip 23.1: JDK Switching

`jdk` flips `JAVA_HOME` (and `PATH`) between Homebrew-installed OpenJDKs.

```sh
jdk 17           # switch to OpenJDK 17
jdk 21           # switch to OpenJDK 21
jdk              # show currently active JDK and available versions
echo $JAVA_HOME  # see where it pointed JAVA_HOME
```

Requires the matching `openjdk@17` / `openjdk@21` Homebrew formulae installed (already in `init/31_homebrew_recipes.sh`). From `source/10_java.sh`.

## Tip 23.2: Maven OpenRewrite Recipes

Run [OpenRewrite](https://docs.openrewrite.org/) refactoring recipes against the current Maven project. Useful for big migrations.

```sh
mvn-check-tests              # run the test suite, summarise pass/fail counts
mvn-rewrite-junit            # migrate JUnit 4 → JUnit 5
mvn-rewrite-asserts          # migrate Hamcrest/JUnit asserts → AssertJ
mvn-rewrite-runwith          # migrate @RunWith → @ExtendWith (JUnit 5)
```

These are thin wrappers around the corresponding `mvn org.openrewrite.maven:rewrite-maven-plugin:run` invocations, so the Maven project must have OpenRewrite available. From `source/45_maven.sh`.

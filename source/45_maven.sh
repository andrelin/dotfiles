# Maven helper functions.
[[ ! "$(command -v mvn)" ]] && return 0

# Run tests and show summary.
check-tests() {
    mvn clean verify | grep run: | grep -v elapsed
}

# OpenRewrite recipes for common migrations.
rewrite-junit() {
    mvn -U org.openrewrite.maven:rewrite-maven-plugin:run \
    -Drewrite.recipeArtifactCoordinates=org.openrewrite.recipe:rewrite-testing-frameworks:RELEASE \
    -Drewrite.activeRecipes=org.openrewrite.java.testing.junit5.JUnit5BestPractices
}

rewrite-asserts() {
    mvn -U org.openrewrite.maven:rewrite-maven-plugin:run \
    -Drewrite.recipeArtifactCoordinates=org.openrewrite.recipe:rewrite-testing-frameworks:RELEASE \
    -Drewrite.activeRecipes=org.openrewrite.java.testing.assertj.Assertj
}

rewrite-runwith() {
    mvn -U org.openrewrite.maven:rewrite-maven-plugin:run \
    -Drewrite.recipeArtifactCoordinates=org.openrewrite.recipe:rewrite-spring:RELEASE \
    -Drewrite.activeRecipes=org.openrewrite.java.spring.boot2.UnnecessarySpringRunWith
}

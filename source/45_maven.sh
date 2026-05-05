# Maven helper functions.
[[ ! "$(command -v mvn)" ]] && return 0

# Run tests and show summary.
mvn-check-tests() {
    mvn clean verify | grep run: | grep -v elapsed
}

# OpenRewrite recipes for common migrations.
mvn-rewrite-junit() {
    mvn -U org.openrewrite.maven:rewrite-maven-plugin:run \
    -Drewrite.recipeArtifactCoordinates=org.openrewrite.recipe:rewrite-testing-frameworks:RELEASE \
    -Drewrite.activeRecipes=org.openrewrite.java.testing.junit5.JUnit5BestPractices
}

mvn-rewrite-asserts() {
    mvn -U org.openrewrite.maven:rewrite-maven-plugin:run \
    -Drewrite.recipeArtifactCoordinates=org.openrewrite.recipe:rewrite-testing-frameworks:RELEASE \
    -Drewrite.activeRecipes=org.openrewrite.java.testing.assertj.Assertj
}

mvn-rewrite-runwith() {
    mvn -U org.openrewrite.maven:rewrite-maven-plugin:run \
    -Drewrite.recipeArtifactCoordinates=org.openrewrite.recipe:rewrite-spring:RELEASE \
    -Drewrite.activeRecipes=org.openrewrite.java.spring.boot2.UnnecessarySpringRunWith
}

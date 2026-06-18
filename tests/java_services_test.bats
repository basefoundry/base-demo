#!/usr/bin/env bats

setup() {
  TEST_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd -P)"
}

@test "java gradle and maven service files are present" {
  grep -Fq 'brew "gradle"' "$TEST_ROOT/Brewfile"
  grep -Fq 'brew "maven"' "$TEST_ROOT/Brewfile"

  [ -f "$TEST_ROOT/services/java-gradle-api/settings.gradle" ]
  [ -f "$TEST_ROOT/services/java-gradle-api/build.gradle" ]
  [ -f "$TEST_ROOT/services/java-gradle-api/src/main/java/com/codeforester/basedemo/javagradle/JavaGradleApi.java" ]
  [ -f "$TEST_ROOT/services/java-gradle-api/src/test/java/com/codeforester/basedemo/javagradle/JavaGradleApiTest.java" ]
  [ -x "$TEST_ROOT/services/java-gradle-api/build.sh" ]
  [ -x "$TEST_ROOT/services/java-gradle-api/test.sh" ]
  [ -x "$TEST_ROOT/services/java-gradle-api/run.sh" ]

  [ -f "$TEST_ROOT/services/java-maven-api/pom.xml" ]
  [ -f "$TEST_ROOT/services/java-maven-api/src/main/java/com/codeforester/basedemo/javamaven/JavaMavenApi.java" ]
  [ -f "$TEST_ROOT/services/java-maven-api/src/test/java/com/codeforester/basedemo/javamaven/JavaMavenApiTest.java" ]
  [ -x "$TEST_ROOT/services/java-maven-api/build.sh" ]
  [ -x "$TEST_ROOT/services/java-maven-api/test.sh" ]
  [ -x "$TEST_ROOT/services/java-maven-api/run.sh" ]
}

@test "services status shows java build tool services" {
  run "$TEST_ROOT/bin/base-demo-services" status

  [ "$status" -eq 0 ]
  [[ "$output" == *"java-gradle-api"* ]]
  [[ "$output" == *"java-gradle"* ]]
  [[ "$output" == *"8030"* ]]
  [[ "$output" == *"java-maven-api"* ]]
  [[ "$output" == *"java-maven"* ]]
  [[ "$output" == *"8040"* ]]
}

@test "services lifecycle dry-run includes java process commands" {
  run env BASE_DEMO_SERVICES_DRY_RUN=1 "$TEST_ROOT/bin/base-demo-services" start

  [ "$status" -eq 0 ]
  [[ "$output" == *"DRY-RUN start java-gradle-api"* ]]
  [[ "$output" == *"services/java-gradle-api/run.sh"* ]]
  [[ "$output" == *"DRY-RUN start java-maven-api"* ]]
  [[ "$output" == *"services/java-maven-api/run.sh"* ]]
}

@test "java service build and test scripts pass" {
  run "$TEST_ROOT/services/java-gradle-api/build.sh"
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/services/java-gradle-api/test.sh"
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/services/java-maven-api/build.sh"
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/services/java-maven-api/test.sh"
  [ "$status" -eq 0 ]
}

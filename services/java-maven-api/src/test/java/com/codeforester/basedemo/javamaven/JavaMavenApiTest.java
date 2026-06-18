package com.codeforester.basedemo.javamaven;

public final class JavaMavenApiTest {
    private JavaMavenApiTest() {
    }

    public static void main(String[] args) {
        assertContains(JavaMavenApi.responseFor("/healthz"), "\"status\":\"ok\"");
        assertContains(JavaMavenApi.responseFor("/hello"), "hello from java-maven-api");
        assertContains(JavaMavenApi.responseFor("/info"), "\"runtime\":\"java-maven\"");
        assertContains(JavaMavenApi.responseFor("/info"), "\"port\":8040");
        if (JavaMavenApi.statusFor("/missing") != 404) {
            throw new AssertionError("missing path should return 404");
        }
        System.out.println("java-maven-api tests passed");
    }

    private static void assertContains(String actual, String expected) {
        if (!actual.contains(expected)) {
            throw new AssertionError("expected " + actual + " to contain " + expected);
        }
    }
}

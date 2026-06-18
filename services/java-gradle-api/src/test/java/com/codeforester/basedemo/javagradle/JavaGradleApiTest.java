package com.codeforester.basedemo.javagradle;

public final class JavaGradleApiTest {
    private JavaGradleApiTest() {
    }

    public static void main(String[] args) {
        assertContains(JavaGradleApi.responseFor("/healthz"), "\"status\":\"ok\"");
        assertContains(JavaGradleApi.responseFor("/hello"), "hello from java-gradle-api");
        assertContains(JavaGradleApi.responseFor("/info"), "\"runtime\":\"java-gradle\"");
        assertContains(JavaGradleApi.responseFor("/info"), "\"port\":8030");
        if (JavaGradleApi.statusFor("/missing") != 404) {
            throw new AssertionError("missing path should return 404");
        }
        System.out.println("java-gradle-api tests passed");
    }

    private static void assertContains(String actual, String expected) {
        if (!actual.contains(expected)) {
            throw new AssertionError("expected " + actual + " to contain " + expected);
        }
    }
}

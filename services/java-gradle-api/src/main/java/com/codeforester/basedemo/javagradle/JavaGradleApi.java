package com.codeforester.basedemo.javagradle;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;

public final class JavaGradleApi {
    public static final int DEFAULT_PORT = 8030;
    private static final String SERVICE_NAME = "java-gradle-api";
    private static final String RUNTIME_NAME = "java-gradle";

    private JavaGradleApi() {
    }

    public static void main(String[] args) throws IOException {
        int listenPort = port();
        HttpServer server = HttpServer.create(new InetSocketAddress("127.0.0.1", listenPort), 0);
        server.createContext("/", JavaGradleApi::handle);
        server.start();
        System.out.println(SERVICE_NAME + " listening on http://127.0.0.1:" + listenPort);
    }

    public static String responseFor(String path) {
        if ("/healthz".equals(path)) {
            return "{\"service\":\"" + SERVICE_NAME + "\",\"status\":\"ok\"}";
        }
        if ("/hello".equals(path)) {
            return "{\"service\":\"" + SERVICE_NAME + "\",\"message\":\"hello from java-gradle-api\"}";
        }
        if ("/info".equals(path)) {
            return "{\"service\":\"" + SERVICE_NAME + "\",\"runtime\":\"" + RUNTIME_NAME + "\",\"port\":" + DEFAULT_PORT + "}";
        }
        return "{\"error\":\"not found\"}";
    }

    public static int statusFor(String path) {
        return "/healthz".equals(path) || "/hello".equals(path) || "/info".equals(path) ? 200 : 404;
    }

    private static int port() {
        String value = System.getenv("PORT");
        if (value == null || value.isEmpty()) {
            return DEFAULT_PORT;
        }
        return Integer.parseInt(value);
    }

    private static void handle(HttpExchange exchange) throws IOException {
        String path = exchange.getRequestURI().getPath();
        byte[] body = responseFor(path).getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "application/json");
        exchange.sendResponseHeaders(statusFor(path), body.length);
        try (OutputStream stream = exchange.getResponseBody()) {
            stream.write(body);
        }
    }
}

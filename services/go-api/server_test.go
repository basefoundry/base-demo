package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestHealthHandler(t *testing.T) {
	request := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	response := httptest.NewRecorder()

	healthHandler(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusOK)
	}
	if !strings.Contains(response.Body.String(), `"status":"ok"`) {
		t.Fatalf("body %q does not include status ok", response.Body.String())
	}
}

func TestHelloHandler(t *testing.T) {
	request := httptest.NewRequest(http.MethodGet, "/hello", nil)
	response := httptest.NewRecorder()

	helloHandler(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusOK)
	}
	if !strings.Contains(response.Body.String(), `"service":"go-api"`) {
		t.Fatalf("body %q does not include service name", response.Body.String())
	}
}

func TestInfoHandler(t *testing.T) {
	request := httptest.NewRequest(http.MethodGet, "/info", nil)
	response := httptest.NewRecorder()

	infoHandler(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusOK)
	}
	body := response.Body.String()
	for _, expected := range []string{`"service":"go-api"`, `"runtime":"go"`, `"port":8010`} {
		if !strings.Contains(body, expected) {
			t.Fatalf("body %q does not include %s", body, expected)
		}
	}
}

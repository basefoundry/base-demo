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

	newServeMux().ServeHTTP(response, request)

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

	newServeMux().ServeHTTP(response, request)

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

	newServeMux().ServeHTTP(response, request)

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

func TestInfoHandlerUsesResolvedPort(t *testing.T) {
	t.Setenv("PORT", "9999")
	request := httptest.NewRequest(http.MethodGet, "/info", nil)
	response := httptest.NewRecorder()

	newServeMux().ServeHTTP(response, request)

	if !strings.Contains(response.Body.String(), `"port":9999`) {
		t.Fatalf("body %q does not include resolved port", response.Body.String())
	}
}

func TestServeMuxReturnsNotFoundForUnknownRoute(t *testing.T) {
	request := httptest.NewRequest(http.MethodGet, "/missing", nil)
	response := httptest.NewRecorder()

	newServeMux().ServeHTTP(response, request)

	if response.Code != http.StatusNotFound {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusNotFound)
	}
}

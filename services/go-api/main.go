package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"strconv"
)

const (
	serviceName = "go-api"
	runtimeName = "go"
	defaultPort = 8010
)

func writeJSON(response http.ResponseWriter, payload map[string]any) {
	response.Header().Set("Content-Type", "application/json")
	response.WriteHeader(http.StatusOK)
	if err := json.NewEncoder(response).Encode(payload); err != nil {
		log.Printf("write response: %v", err)
	}
}

func healthHandler(response http.ResponseWriter, request *http.Request) {
	writeJSON(response, map[string]any{
		"service": serviceName,
		"status":  "ok",
	})
}

func helloHandler(response http.ResponseWriter, request *http.Request) {
	writeJSON(response, map[string]any{
		"service": serviceName,
		"message": "hello from go-api",
	})
}

func infoHandler(response http.ResponseWriter, request *http.Request) {
	writeJSON(response, map[string]any{
		"service": serviceName,
		"runtime": runtimeName,
		"port":    port(),
	})
}

func port() int {
	value := os.Getenv("PORT")
	if value == "" {
		return defaultPort
	}
	resolved, err := strconv.Atoi(value)
	if err != nil {
		log.Fatalf("invalid PORT %q: %v", value, err)
	}
	return resolved
}

func newServeMux() *http.ServeMux {
	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", healthHandler)
	mux.HandleFunc("/hello", helloHandler)
	mux.HandleFunc("/info", infoHandler)
	return mux
}

func main() {
	address := ":" + strconv.Itoa(port())
	log.Printf("%s listening on %s", serviceName, address)
	if err := http.ListenAndServe(address, newServeMux()); err != nil {
		log.Fatal(err)
	}
}

package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
)

const (
	serviceName = "go-api"
	runtimeName = "go"
	defaultPort = "8010"
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
		"port":    8010,
	})
}

func port() string {
	value := os.Getenv("PORT")
	if value == "" {
		return defaultPort
	}
	return value
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", healthHandler)
	mux.HandleFunc("/hello", helloHandler)
	mux.HandleFunc("/info", infoHandler)

	address := ":" + port()
	log.Printf("%s listening on %s", serviceName, address)
	if err := http.ListenAndServe(address, mux); err != nil {
		log.Fatal(err)
	}
}

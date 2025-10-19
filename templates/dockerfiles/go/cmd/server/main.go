package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"runtime"

	"github.com/gorilla/mux"
)

type Response struct {
	Message     string `json:"message"`
	GoVersion   string `json:"go_version"`
	Environment string `json:"environment"`
}

type HealthResponse struct {
	Status string `json:"status"`
}

func main() {
	r := mux.NewRouter()

	r.HandleFunc("/", homeHandler).Methods("GET")
	r.HandleFunc("/health", healthHandler).Methods("GET")

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server starting on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, r))
}

func homeHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	env := os.Getenv("ENVIRONMENT")
	if env == "" {
		env = "development"
	}

	response := Response{
		Message:     "Go Docker Template",
		GoVersion:   runtime.Version(),
		Environment: env,
	}

	json.NewEncoder(w).Encode(response)
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	response := HealthResponse{
		Status: "healthy",
	}

	json.NewEncoder(w).Encode(response)
}

//go:build integration
// +build integration

package integration

import (
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/google/uuid"
	"log"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"

	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/config"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/server"
)

var router *gin.Engine

func TestMain(m *testing.M) {
	os.Setenv("DATABASE_URL", "postgres://testuser:testpass@localhost:5432/testdb?sslmode=disable")
	os.Setenv("JWT_SECRET", "test-secret")

	cmd := exec.Command("go", "run", "../../cmd/migrate/main.go", "up")

	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		log.Fatalf("failed to migrate test DB: %v", err)
	}

	cfg := config.Load()
	var err error
	router, err = server.NewRouter(cfg)
	if err != nil {
		log.Fatalf("failed to create router: %v", err)
	}
	gin.SetMode(gin.TestMode)

	os.Exit(m.Run())
}

func TestRegisterAndProfile(t *testing.T) {
	// use a unique email each run:
	uid := uuid.NewString()
	email := fmt.Sprintf("int+%s@test.com", uid)

	// 1) Register
	registerPayload := map[string]string{
		"name":     "Integration Test",
		"email":    email,
		"password": "pwd",
	}
	body, _ := json.Marshal(registerPayload)
	w := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/api/users/register", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	router.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code, "register should return 200")

	// 2) Login
	loginPayload := map[string]string{
		"email":    email,
		"password": "pwd",
	}
	body, _ = json.Marshal(loginPayload)
	w = httptest.NewRecorder()
	req = httptest.NewRequest(http.MethodPost, "/api/users/login", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	router.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code, "login should return 200")

	var loginResp struct{ Token string }
	if err := json.NewDecoder(w.Body).Decode(&loginResp); err != nil {
		t.Fatalf("failed to decode login response: %v", err)
	}
	assert.NotEmpty(t, loginResp.Token, "expected non-empty JWT")

	// 3) Get profile
	w = httptest.NewRecorder()
	req = httptest.NewRequest(http.MethodGet, "/api/users/profile", nil)
	req.Header.Set("Authorization", "Bearer "+loginResp.Token)
	router.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code, "profile should return 200")
}

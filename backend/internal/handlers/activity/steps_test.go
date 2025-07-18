package activity

import (
	"bytes"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"

	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/services"
)

type mockStepSvc struct {
	updateErr    error
	statsRes     services.StepStats
	statsErr     error
	analyticsRes []services.StepDay
	analyticsErr error
	setGoalErr   error
	goalRes      int
	goalErr      error
}

func (m *mockStepSvc) AddOrUpdateSteps(userID string, steps int) error {
	return m.updateErr
}
func (m *mockStepSvc) AwardStepAchievements(userID string) error { return nil }
func (m *mockStepSvc) GetStepStats(userID string, goal int) (services.StepStats, error) {
	return m.statsRes, m.statsErr
}
func (m *mockStepSvc) GetStepAnalytics(userID string, days int) ([]services.StepDay, error) {
	return m.analyticsRes, m.analyticsErr
}
func (m *mockStepSvc) SetStepGoal(userID string, goal int) error {
	return m.setGoalErr
}
func (m *mockStepSvc) GetStepGoal(userID string) (int, error) {
	return m.goalRes, m.goalErr
}

func setupStepsTest(mock *mockStepSvc, req *http.Request) (*gin.Context, *httptest.ResponseRecorder) {
	gin.SetMode(gin.TestMode)
	ResetStepService(mock)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = req
	c.Set("userID", "test-user")
	return c, w
}

func TestAddSteps_Success(t *testing.T) {
	mock := &mockStepSvc{updateErr: nil}
	body := `{"steps":1234}`
	req := httptest.NewRequest(http.MethodPost, "/", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")

	c, w := setupStepsTest(mock, req)
	AddSteps(c)

	assert.Equal(t, http.StatusOK, w.Code)
}

func TestAddSteps_BadJSON(t *testing.T) {
	mock := &mockStepSvc{}
	req := httptest.NewRequest(http.MethodPost, "/", bytes.NewBufferString(`not-json`))
	req.Header.Set("Content-Type", "application/json")

	c, w := setupStepsTest(mock, req)
	AddSteps(c)

	assert.Equal(t, http.StatusBadRequest, w.Code)
	var resp map[string]string
	err := json.Unmarshal(w.Body.Bytes(), &resp)
	assert.NoError(t, err)
	assert.Contains(t, resp["error"], "invalid character")
}

func TestAddSteps_DBError(t *testing.T) {
	mock := &mockStepSvc{updateErr: errors.New("db fail")}
	body := `{"steps":10}`
	req := httptest.NewRequest(http.MethodPost, "/", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")

	c, w := setupStepsTest(mock, req)
	AddSteps(c)

	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

func TestGetStepStats_Success(t *testing.T) {
	mock := &mockStepSvc{
		statsRes: services.StepStats{
			Today:        100,
			Goal:         200,
			Progress:     0.5,
			WeeklyTotal:  700,
			MonthlyTotal: 3000,
		},
		statsErr: nil,
	}
	req := httptest.NewRequest(http.MethodGet, "/", nil)

	c, w := setupStepsTest(mock, req)
	GetStepStats(c)

	assert.Equal(t, http.StatusOK, w.Code)
	var resp services.StepStats
	err := json.Unmarshal(w.Body.Bytes(), &resp)
	assert.NoError(t, err)
	assert.Equal(t, 100, resp.Today)
	assert.Equal(t, 200, resp.Goal)
	assert.Equal(t, 0.5, resp.Progress)
	assert.Equal(t, 700, resp.WeeklyTotal)
	assert.Equal(t, 3000, resp.MonthlyTotal)
}

func TestGetStepStats_ServiceError(t *testing.T) {
	mock := &mockStepSvc{statsErr: errors.New("fail")}
	req := httptest.NewRequest(http.MethodGet, "/", nil)

	c, w := setupStepsTest(mock, req)
	GetStepStats(c)

	assert.Equal(t, http.StatusInternalServerError, w.Code)
	var resp map[string]string
	err := json.Unmarshal(w.Body.Bytes(), &resp)
	assert.NoError(t, err)
	assert.Equal(t, "failed to get step stats", resp["error"])
}

func TestGetStepAnalytics_DefaultDays(t *testing.T) {
	mock := &mockStepSvc{
		analyticsRes: []services.StepDay{
			{Day: "2025-07-18", Steps: 1000},
		},
		analyticsErr: nil,
	}
	req := httptest.NewRequest(http.MethodGet, "/", nil)

	c, w := setupStepsTest(mock, req)
	GetStepAnalytics(c)

	assert.Equal(t, http.StatusOK, w.Code)
	var resp []services.StepDay
	err := json.Unmarshal(w.Body.Bytes(), &resp)
	assert.NoError(t, err)
	assert.Len(t, resp, 1)
	assert.Equal(t, "2025-07-18", resp[0].Day)
	assert.Equal(t, 1000, resp[0].Steps)
}

func TestGetStepAnalytics_CustomDays(t *testing.T) {
	mock := &mockStepSvc{
		analyticsRes: []services.StepDay{{Day: "D", Steps: 1}},
	}
	req := httptest.NewRequest(http.MethodGet, "/?days=7", nil)

	c, w := setupStepsTest(mock, req)
	GetStepAnalytics(c)

	assert.Equal(t, http.StatusOK, w.Code)
}

func TestGetStepAnalytics_BadQuery(t *testing.T) {
	mock := &mockStepSvc{analyticsRes: []services.StepDay{{Day: "X", Steps: 1}}}
	req := httptest.NewRequest(http.MethodGet, "/?days=abc", nil)

	c, w := setupStepsTest(mock, req)
	GetStepAnalytics(c)

	assert.Equal(t, http.StatusOK, w.Code)
}

func TestGetStepAnalytics_ServiceError(t *testing.T) {
	mock := &mockStepSvc{analyticsErr: errors.New("fail")}
	req := httptest.NewRequest(http.MethodGet, "/", nil)

	c, w := setupStepsTest(mock, req)
	GetStepAnalytics(c)

	assert.Equal(t, http.StatusInternalServerError, w.Code)
	var resp map[string]string
	err := json.Unmarshal(w.Body.Bytes(), &resp)
	assert.NoError(t, err)
	assert.Equal(t, "failed to get analytics", resp["error"])
}

func TestSetStepGoal_Success(t *testing.T) {
	mock := &mockStepSvc{setGoalErr: nil}
	body := `{"goal":1500}`
	req := httptest.NewRequest(http.MethodPost, "/", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")

	c, w := setupStepsTest(mock, req)
	SetStepGoal(c)

	assert.Equal(t, http.StatusOK, w.Code)
	var resp map[string]bool
	err := json.Unmarshal(w.Body.Bytes(), &resp)
	assert.NoError(t, err)
	assert.True(t, resp["success"])
}

func TestSetStepGoal_BadJSON(t *testing.T) {
	mock := &mockStepSvc{}
	req := httptest.NewRequest(http.MethodPost, "/", bytes.NewBufferString(`bad`))
	req.Header.Set("Content-Type", "application/json")

	c, w := setupStepsTest(mock, req)
	SetStepGoal(c)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestSetStepGoal_ServiceError(t *testing.T) {
	mock := &mockStepSvc{setGoalErr: errors.New("fail")}
	body := `{"goal":2000}`
	req := httptest.NewRequest(http.MethodPost, "/", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")

	c, w := setupStepsTest(mock, req)
	SetStepGoal(c)

	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

func TestGetStepGoal_Success(t *testing.T) {
	mock := &mockStepSvc{goalRes: 5000, goalErr: nil}
	req := httptest.NewRequest(http.MethodGet, "/", nil)

	c, w := setupStepsTest(mock, req)
	GetStepGoal(c)

	assert.Equal(t, http.StatusOK, w.Code)
	var resp map[string]int
	err := json.Unmarshal(w.Body.Bytes(), &resp)
	assert.NoError(t, err)
	assert.Equal(t, 5000, resp["goal"])
}

func TestGetStepGoal_ServiceError(t *testing.T) {
	mock := &mockStepSvc{goalErr: errors.New("fail")}
	req := httptest.NewRequest(http.MethodGet, "/", nil)

	c, w := setupStepsTest(mock, req)
	GetStepGoal(c)

	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

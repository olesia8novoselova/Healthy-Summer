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

	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/models"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/services"
)

type mockUserSvc struct {
	addCalled     bool
	addErr        error
	listCalled    bool
	listRes       []models.Activity
	listErr       error
	goalCalled    bool
	goalErr       error
	getGoalCalled bool
	getGoal       int
	getGoalErr    error
	todayCalled   bool
	todayCalories int
	todayErr      error
	weeklyCalled  bool
	weeklyStats   []services.ActivityStats
	weeklyErr     error
}

type mockChallengeSvc struct{}

func (m *mockChallengeSvc) BumpProgress(userID, metric string, amount int) error {
	return nil
}

func (m *mockUserSvc) AddActivity(userID, typ, name string, duration int, intensity string, calories int, location string) error {
	m.addCalled = true
	return m.addErr
}

func (m *mockUserSvc) ListActivities(userID string, filter *string) ([]models.Activity, error) {
	m.listCalled = true
	return m.listRes, m.listErr
}

func (m *mockUserSvc) SetActivityGoal(userID string, goal int) error {
	m.goalCalled = true
	return m.goalErr
}

func (m *mockUserSvc) GetActivityGoal(userID string) (int, error) {
	m.getGoalCalled = true
	return m.getGoal, m.getGoalErr
}

func (m *mockUserSvc) GetTodayCalories(userID string) (int, error) {
	m.todayCalled = true
	return m.todayCalories, m.todayErr
}

func (m *mockUserSvc) GetWeeklyStats(userID string) ([]services.ActivityStats, error) {
	m.weeklyCalled = true
	return m.weeklyStats, m.weeklyErr
}

func setupTest(t *testing.T, mock *mockUserSvc, req *http.Request) (*gin.Context, *httptest.ResponseRecorder) {
	gin.SetMode(gin.TestMode)
	ResetUserService(mock)
	ResetChallengeService(&mockChallengeSvc{})
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = req
	c.Set("userID", "user-1")
	return c, w
}

func TestAddActivity_Success(t *testing.T) {
	mock := &mockUserSvc{addErr: nil}
	body := `{"type":"run","name":"morning run","duration":30,"intensity":"low","calories":200,"location":"park"}`
	req := httptest.NewRequest(http.MethodPost, "/", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")

	c, w := setupTest(t, mock, req)
	AddActivity(c)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.True(t, mock.addCalled, "AddActivity should call service")
}

func TestAddActivity_ServiceError(t *testing.T) {
	mock := &mockUserSvc{addErr: errors.New("oops")}
	body := `{"type":"run","name":"x","duration":10,"intensity":"high","calories":100,"location":""}`
	req := httptest.NewRequest(http.MethodPost, "/", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")

	c, w := setupTest(t, mock, req)
	AddActivity(c)

	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

func TestListActivities_Success(t *testing.T) {
	mock := &mockUserSvc{
		listRes: []models.Activity{},
		listErr: nil,
	}
	req := httptest.NewRequest(http.MethodGet, "/", nil)

	c, w := setupTest(t, mock, req)
	ListActivities(c)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.True(t, mock.listCalled, "ListActivities should call service")
	assert.Equal(t, "[]", w.Body.String())
}

func TestListActivities_ServiceError(t *testing.T) {
	mock := &mockUserSvc{listErr: errors.New("fail")}
	req := httptest.NewRequest(http.MethodGet, "/", nil)

	c, w := setupTest(t, mock, req)
	ListActivities(c)

	assert.Equal(t, http.StatusInternalServerError, w.Code)
	var resp map[string]string
	err := json.Unmarshal(w.Body.Bytes(), &resp)
	assert.NoError(t, err)
	assert.Equal(t, "failed to fetch activities", resp["error"])
}

func TestSetActivityGoal_Success(t *testing.T) {
	mock := &mockUserSvc{goalErr: nil}
	body := `{"goal":100}`
	req := httptest.NewRequest(http.MethodPost, "/", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")

	c, w := setupTest(t, mock, req)
	SetActivityGoal(c)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.True(t, mock.goalCalled, "SetActivityGoal should call service")

	var resp map[string]bool
	err := json.Unmarshal(w.Body.Bytes(), &resp)
	assert.NoError(t, err)
	assert.True(t, resp["success"])
}

func TestSetActivityGoal_BadJSON(t *testing.T) {
	mock := &mockUserSvc{}
	req := httptest.NewRequest(http.MethodPost, "/", bytes.NewBufferString(`bad-json`))
	req.Header.Set("Content-Type", "application/json")

	c, w := setupTest(t, mock, req)
	SetActivityGoal(c)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestGetActivityGoal_Success(t *testing.T) {
	mock := &mockUserSvc{getGoal: 42, getGoalErr: nil}
	req := httptest.NewRequest(http.MethodGet, "/", nil)

	c, w := setupTest(t, mock, req)
	GetActivityGoal(c)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.True(t, mock.getGoalCalled, "GetActivityGoal should call service")

	var resp map[string]int
	err := json.Unmarshal(w.Body.Bytes(), &resp)
	assert.NoError(t, err)
	assert.Equal(t, 42, resp["goal"])
}

func TestGetActivityGoal_ServiceError(t *testing.T) {
	mock := &mockUserSvc{getGoalErr: errors.New("fail")}
	req := httptest.NewRequest(http.MethodGet, "/", nil)

	c, w := setupTest(t, mock, req)
	GetActivityGoal(c)

	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

func TestGetTodayActivityCalories_Success(t *testing.T) {
	mock := &mockUserSvc{todayCalories: 123, todayErr: nil}
	req := httptest.NewRequest(http.MethodGet, "/", nil)

	c, w := setupTest(t, mock, req)
	GetTodayActivityCalories(c)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.True(t, mock.todayCalled, "GetTodayActivityCalories should call service")

	var resp map[string]int
	err := json.Unmarshal(w.Body.Bytes(), &resp)
	assert.NoError(t, err)
	assert.Equal(t, 123, resp["calories"])
}

func TestGetTodayActivityCalories_ServiceError(t *testing.T) {
	mock := &mockUserSvc{todayErr: errors.New("fail")}
	req := httptest.NewRequest(http.MethodGet, "/", nil)

	c, w := setupTest(t, mock, req)
	GetTodayActivityCalories(c)

	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

func TestGetWeeklyActivityStats_Success(t *testing.T) {
	mock := &mockUserSvc{
		weeklyStats: []services.ActivityStats{
			{Date: "2025-07-18", Calories: 100, Duration: 30},
		},
		weeklyErr: nil,
	}
	req := httptest.NewRequest(http.MethodGet, "/", nil)

	c, w := setupTest(t, mock, req)
	GetWeeklyActivityStats(c)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.True(t, mock.weeklyCalled, "GetWeeklyActivityStats should call service")

	var resp []services.ActivityStats
	err := json.Unmarshal(w.Body.Bytes(), &resp)
	assert.NoError(t, err)
	assert.Len(t, resp, 1)
	assert.Equal(t, "2025-07-18", resp[0].Date)
	assert.Equal(t, 100.0, resp[0].Calories)
	assert.Equal(t, 30.0, resp[0].Duration)
}

func TestGetWeeklyActivityStats_ServiceError(t *testing.T) {
	mock := &mockUserSvc{weeklyErr: errors.New("fail")}
	req := httptest.NewRequest(http.MethodGet, "/", nil)

	c, w := setupTest(t, mock, req)
	GetWeeklyActivityStats(c)

	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

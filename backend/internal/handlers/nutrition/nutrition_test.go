package nutrition

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"

	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/models"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/services"
)

type mockNutritionSvc struct {
	addMealErr          error
	listMealsRes        []services.Meal
	listMealsErr        error
	statsRes            services.NutritionStats
	statsErr            error
	weeklyStatsRes      []services.NutritionStats
	weeklyStatsErr      error
	addWaterLogErr      error
	todayWaterStatsRes  services.DailyWaterStats
	todayWaterStatsErr  error
	weeklyWaterStatsRes []services.DailyWaterStats
	weeklyWaterStatsErr error
	setWaterGoalErr     error
	getWaterGoalRes     int
	getWaterGoalErr     error
	setCalorieGoalErr   error
	getCalorieGoalRes   int
	getCalorieGoalErr   error
}

func (m *mockNutritionSvc) AddMeal(userID string, meal services.Meal) error {
	return m.addMealErr
}
func (m *mockNutritionSvc) ListMeals(userID string) ([]services.Meal, error) {
	return m.listMealsRes, m.listMealsErr
}
func (m *mockNutritionSvc) GetNutritionStats(userID string) (services.NutritionStats, error) {
	return m.statsRes, m.statsErr
}
func (m *mockNutritionSvc) GetWeeklyNutritionStats(userID string) ([]services.NutritionStats, error) {
	return m.weeklyStatsRes, m.weeklyStatsErr
}
func (m *mockNutritionSvc) AddWaterLog(userID string, amt int) error {
	return m.addWaterLogErr
}
func (m *mockNutritionSvc) GetTodayWaterStats(userID string) (services.DailyWaterStats, error) {
	return m.todayWaterStatsRes, m.todayWaterStatsErr
}
func (m *mockNutritionSvc) GetWeeklyWaterStats(userID string) ([]services.DailyWaterStats, error) {
	return m.weeklyWaterStatsRes, m.weeklyWaterStatsErr
}
func (m *mockNutritionSvc) SetWaterGoal(userID string, g int) error {
	return m.setWaterGoalErr
}
func (m *mockNutritionSvc) GetWaterGoal(userID string) (int, error) {
	return m.getWaterGoalRes, m.getWaterGoalErr
}
func (m *mockNutritionSvc) SetCalorieGoal(userID string, g int) error {
	return m.setCalorieGoalErr
}
func (m *mockNutritionSvc) GetCalorieGoal(userID string) (int, error) {
	return m.getCalorieGoalRes, m.getCalorieGoalErr
}

type mockChallengeSvc struct {
	createRes      models.Challenge
	createErr      error
	joinErr        error
	leaderboardRes []models.ChallengeParticipant
	leaderboardErr error
	listForUserRes []models.Challenge
	listForUserErr error
	bumpErr        error
}

func (m *mockChallengeSvc) Create(
	creatorID, title, ctype string, target int, friends []string,
) (models.Challenge, error) {
	return m.createRes, m.createErr
}

func (m *mockChallengeSvc) Join(chID, userID string) error {
	return m.joinErr
}

func (m *mockChallengeSvc) UpdateProgress(userID, activityType string, delta int) {
	// no return
}

func (m *mockChallengeSvc) Leaderboard(chID string) ([]models.ChallengeParticipant, error) {
	return m.leaderboardRes, m.leaderboardErr
}

func (m *mockChallengeSvc) ListForUser(userID string) ([]models.Challenge, error) {
	return m.listForUserRes, m.listForUserErr
}

func (m *mockChallengeSvc) BumpProgress(userID, ctype string, delta int) error {
	return m.bumpErr
}

func setup(r *gin.Engine, body []byte, method, path string, userID interface{}) (*httptest.ResponseRecorder, *gin.Context) {
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest(method, path, bytes.NewReader(body))
	c.Request.Header.Set("Content-Type", "application/json")
	if userID != nil {
		c.Set("userID", userID)
	}
	r.HandleContext(c)
	return w, c
}

func TestAddMeal_Success(t *testing.T) {
	gin.SetMode(gin.TestMode)
	mockN := &mockNutritionSvc{}
	mockC := &mockChallengeSvc{}
	services.Nutrition = mockN
	services.Challenge = mockC

	meal := services.Meal{Calories: 123}
	b, _ := json.Marshal(meal)
	r := gin.New()
	r.POST("/", AddMeal)

	w, _ := setup(r, b, "POST", "/", "u1")
	assert.Equal(t, http.StatusOK, w.Code)
}

func TestAddMeal_BadJSON(t *testing.T) {
	gin.SetMode(gin.TestMode)
	services.Nutrition = &mockNutritionSvc{}
	services.Challenge = &mockChallengeSvc{}

	r := gin.New()
	r.POST("/", AddMeal)
	w, _ := setup(r, []byte(`not-json`), "POST", "/", "u1")
	assert.Equal(t, http.StatusBadRequest, w.Code)
	var resp map[string]string
	assert.NoError(t, json.Unmarshal(w.Body.Bytes(), &resp))
	assert.Contains(t, resp["error"], "invalid character")
}

func TestAddMeal_ServiceError(t *testing.T) {
	gin.SetMode(gin.TestMode)
	mockN := &mockNutritionSvc{addMealErr: assert.AnError}
	services.Nutrition = mockN
	services.Challenge = &mockChallengeSvc{}

	meal := services.Meal{Calories: 50}
	b, _ := json.Marshal(meal)
	r := gin.New()
	r.POST("/", AddMeal)

	w, _ := setup(r, b, "POST", "/", "u1")
	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

func TestListMeals_SuccessAndNil(t *testing.T) {
	gin.SetMode(gin.TestMode)
	// Non-nil result
	mockN := &mockNutritionSvc{listMealsRes: []services.Meal{{}}}
	services.Nutrition = mockN
	r := gin.New()
	r.GET("/", ListMeals)

	w, _ := setup(r, nil, "GET", "/", "u1")
	assert.Equal(t, http.StatusOK, w.Code)
	assert.True(t, json.Valid(w.Body.Bytes()))

	mockN = &mockNutritionSvc{listMealsRes: nil}
	services.Nutrition = mockN
	w, _ = setup(r, nil, "GET", "/", "u1")
	assert.Equal(t, http.StatusOK, w.Code)
	var arr []services.Meal
	assert.NoError(t, json.Unmarshal(w.Body.Bytes(), &arr))
	assert.Len(t, arr, 1)
}

func TestListMeals_Error(t *testing.T) {
	gin.SetMode(gin.TestMode)
	mockN := &mockNutritionSvc{listMealsErr: assert.AnError}
	services.Nutrition = mockN
	r := gin.New()
	r.GET("/", ListMeals)

	w, _ := setup(r, nil, "GET", "/", "u1")
	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

func TestGetNutritionStats(t *testing.T) {
	gin.SetMode(gin.TestMode)
	mockN := &mockNutritionSvc{}
	services.Nutrition = mockN
	r := gin.New()
	r.GET("/", GetNutritionStats)

	w, _ := setup(r, nil, "GET", "/", "u1")
	assert.Equal(t, http.StatusOK, w.Code)
	assert.True(t, json.Valid(w.Body.Bytes()))

	// error
	mockN = &mockNutritionSvc{statsErr: assert.AnError}
	services.Nutrition = mockN
	w, _ = setup(r, nil, "GET", "/", "u1")
	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

func TestGetWeeklyNutritionStats(t *testing.T) {
	gin.SetMode(gin.TestMode)
	mockN := &mockNutritionSvc{}
	services.Nutrition = mockN
	r := gin.New()
	r.GET("/", GetWeeklyNutritionStats)

	w, _ := setup(r, nil, "GET", "/", "u1")
	assert.Equal(t, http.StatusOK, w.Code)

	// error
	mockN = &mockNutritionSvc{weeklyStatsErr: assert.AnError}
	services.Nutrition = mockN
	w, _ = setup(r, nil, "GET", "/", "u1")
	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

func TestAddWaterLog(t *testing.T) {
	gin.SetMode(gin.TestMode)
	mockN := &mockNutritionSvc{}
	services.Nutrition = mockN
	r := gin.New()
	r.POST("/", AddWaterLog)

	// success
	b, _ := json.Marshal(waterLogRequest{Amount: 500})
	w, _ := setup(r, b, "POST", "/", "u1")
	assert.Equal(t, http.StatusOK, w.Code)

	// bad JSON
	w, _ = setup(r, []byte(`bad`), "POST", "/", "u1")
	assert.Equal(t, http.StatusBadRequest, w.Code)

	// zero/negative
	b, _ = json.Marshal(waterLogRequest{Amount: 0})
	w, _ = setup(r, b, "POST", "/", "u1")
	assert.Equal(t, http.StatusBadRequest, w.Code)

	// service error
	mockN = &mockNutritionSvc{addWaterLogErr: assert.AnError}
	services.Nutrition = mockN
	b, _ = json.Marshal(waterLogRequest{Amount: 100})
	w, _ = setup(r, b, "POST", "/", "u1")
	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

func TestGetTodayWaterStats(t *testing.T) {
	gin.SetMode(gin.TestMode)
	mockN := &mockNutritionSvc{
		todayWaterStatsRes: services.DailyWaterStats{
			Date:    "2025-07-18",
			TotalML: 1000,
			GoalML:  2000,
		},
	}
	services.Nutrition = mockN

	r := gin.New()
	r.GET("/", GetTodayWaterStats)

	// Success case
	w, _ := setup(r, nil, "GET", "/", "u1")
	assert.Equal(t, http.StatusOK, w.Code)
	assert.True(t, json.Valid(w.Body.Bytes()))

	// Error case
	mockN = &mockNutritionSvc{todayWaterStatsErr: assert.AnError}
	services.Nutrition = mockN

	w, _ = setup(r, nil, "GET", "/", "u1")
	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

func TestSetWaterGoal(t *testing.T) {
	gin.SetMode(gin.TestMode)
	mockN := &mockNutritionSvc{}
	services.Nutrition = mockN
	r := gin.New()
	r.POST("/", SetWaterGoal)

	// success
	b, _ := json.Marshal(map[string]int{"goal_ml": 1500})
	w, _ := setup(r, b, "POST", "/", "u1")
	assert.Equal(t, http.StatusOK, w.Code)
	var resp map[string]bool
	assert.NoError(t, json.Unmarshal(w.Body.Bytes(), &resp))
	assert.True(t, resp["success"])

	// bad JSON
	w, _ = setup(r, []byte(`bad`), "POST", "/", "u1")
	assert.Equal(t, http.StatusBadRequest, w.Code)

	// service error
	mockN = &mockNutritionSvc{setWaterGoalErr: assert.AnError}
	services.Nutrition = mockN
	b, _ = json.Marshal(map[string]int{"goal_ml": 2000})
	w, _ = setup(r, b, "POST", "/", "u1")
	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

func TestGetWaterGoal(t *testing.T) {
	gin.SetMode(gin.TestMode)
	mockN := &mockNutritionSvc{getWaterGoalRes: 2500}
	services.Nutrition = mockN
	r := gin.New()
	r.GET("/", GetWaterGoal)

	w, _ := setup(r, nil, "GET", "/", "u1")
	assert.Equal(t, http.StatusOK, w.Code)
	var resp map[string]int
	assert.NoError(t, json.Unmarshal(w.Body.Bytes(), &resp))
	assert.Equal(t, 2500, resp["goal_ml"])

	// service error
	mockN = &mockNutritionSvc{getWaterGoalErr: assert.AnError}
	services.Nutrition = mockN
	w, _ = setup(r, nil, "GET", "/", "u1")
	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

func TestSetCalorieGoal(t *testing.T) {
	gin.SetMode(gin.TestMode)
	mockN := &mockNutritionSvc{}
	services.Nutrition = mockN
	r := gin.New()
	r.POST("/", SetCalorieGoal)

	// success
	b, _ := json.Marshal(map[string]int{"goal": 1800})
	w, _ := setup(r, b, "POST", "/", "u1")
	assert.Equal(t, http.StatusOK, w.Code)
	var resp map[string]bool
	assert.NoError(t, json.Unmarshal(w.Body.Bytes(), &resp))
	assert.True(t, resp["success"])

	// bad JSON
	w, _ = setup(r, []byte(`bad`), "POST", "/", "u1")
	assert.Equal(t, http.StatusBadRequest, w.Code)

	// service error
	mockN = &mockNutritionSvc{setCalorieGoalErr: assert.AnError}
	services.Nutrition = mockN
	b, _ = json.Marshal(map[string]int{"goal": 2000})
	w, _ = setup(r, b, "POST", "/", "u1")
	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

func TestGetCalorieGoal(t *testing.T) {
	gin.SetMode(gin.TestMode)
	mockN := &mockNutritionSvc{getCalorieGoalRes: 2200}
	services.Nutrition = mockN
	r := gin.New()
	r.GET("/", GetCalorieGoal)

	w, _ := setup(r, nil, "GET", "/", "u1")
	assert.Equal(t, http.StatusOK, w.Code)
	var resp map[string]int
	assert.NoError(t, json.Unmarshal(w.Body.Bytes(), &resp))
	assert.Equal(t, 2200, resp["goal"])

	// service error
	mockN = &mockNutritionSvc{getCalorieGoalErr: assert.AnError}
	services.Nutrition = mockN
	w, _ = setup(r, nil, "GET", "/", "u1")
	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

// backend/internal/handlers/user/user_test.go
package user

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
	allAchievements      []services.Achievement
	allErr               error
	unlockedAchievements []services.Achievement
	unlockedErr          error

	sendRequestErr  error
	friendList      []services.Friend
	friendListErr   error
	acceptErr       error
	declineErr      error
	pendingRequests []services.Friend
	pendingErr      error

	authToken string
	authErr   error

	profile    services.UserProfile
	profileErr error
	updateErr  error

	createUserID string
	createErr    error
	awardErr     error
}

func (m *mockUserSvc) ListAllAchievements() ([]services.Achievement, error) {
	return m.allAchievements, m.allErr
}
func (m *mockUserSvc) ListUnlockedAchievements(userID string) ([]services.Achievement, error) {
	return m.unlockedAchievements, m.unlockedErr
}
func (m *mockUserSvc) SendFriendRequest(userID, email string) error {
	return m.sendRequestErr
}
func (m *mockUserSvc) ListFriends(userID string) ([]services.Friend, error) {
	return m.friendList, m.friendListErr
}
func (m *mockUserSvc) AcceptFriendRequest(userID, requestID string) error {
	return m.acceptErr
}
func (m *mockUserSvc) DeclineFriendRequest(userID, requestID string) error {
	return m.declineErr
}
func (m *mockUserSvc) ListPendingFriendRequests(userID string) ([]services.Friend, error) {
	return m.pendingRequests, m.pendingErr
}
func (m *mockUserSvc) Authenticate(email, pass string) (string, error) {
	return m.authToken, m.authErr
}
func (m *mockUserSvc) GetProfile(userID string) (services.UserProfile, error) {
	return m.profile, m.profileErr
}
func (m *mockUserSvc) UpdateProfile(userID string, in services.ProfileUpdateInput) error {
	return m.updateErr
}
func (m *mockUserSvc) CreateUser(name, email, pass string) (string, error) {
	return m.createUserID, m.createErr
}
func (m *mockUserSvc) AwardAchievementToUserID(userID, title string) error {
	return m.awardErr
}

func (m *mockUserSvc) AddActivity(userID, activityType, name string, duration int, intensity string, calories int, location string) error {
	return nil
}
func (m *mockUserSvc) ListActivities(userID string, filterType *string) ([]models.Activity, error) {
	return nil, nil
}
func (m *mockUserSvc) SetActivityGoal(userID string, goal int) error {
	return nil
}
func (m *mockUserSvc) GetActivityGoal(userID string) (int, error) {
	return 0, nil
}
func (m *mockUserSvc) GetTodayCalories(userID string) (int, error) {
	return 0, nil
}
func (m *mockUserSvc) GetWeeklyStats(userID string) ([]services.ActivityStats, error) {
	return nil, nil
}
func (m *mockUserSvc) GetFriendIDs(userID string) ([]string, error) {
	return nil, nil
}
func (m *mockUserSvc) IDByEmail(email string) (string, error) {
	return "", nil
}

func setupRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	r := gin.New()

	r.GET("/achievements/all", ListAllAchievements)
	r.GET("/achievements/user", ListUserAchievements)

	r.POST("/friends/request", RequestFriend)
	r.POST("/friends/requests/:id/accept", AcceptFriendRequest)
	r.POST("/friends/requests/:id/decline", DeclineFriendRequest)
	r.GET("/friends/requests", ListFriendRequests)
	r.GET("/friends", ListFriends)

	r.POST("/login", Login)
	r.GET("/profile", GetProfile)
	r.PUT("/profile", UpdateProfile)
	r.POST("/register", Register)

	return r
}

func performRequest(r *gin.Engine, method, path string, body interface{}, userID string) *httptest.ResponseRecorder {
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)

	var buf bytes.Buffer
	if body != nil {
		json.NewEncoder(&buf).Encode(body)
	}
	c.Request = httptest.NewRequest(method, path, &buf)
	c.Request.Header.Set("Content-Type", "application/json")
	if userID != "" {
		c.Set("userID", userID)
	}

	r.HandleContext(c)
	return w
}

// --- tests --------------------------------------------------------

func TestListAllAchievements(t *testing.T) {
	mock := &mockUserSvc{
		allAchievements: []services.Achievement{
			{ID: "a1", Title: "X", IconURL: "", Unlocked: false},
		},
	}
	services.User = mock

	r := setupRouter()
	w := performRequest(r, "GET", "/achievements/all", nil, "")
	assert.Equal(t, http.StatusOK, w.Code)

	var got []services.Achievement
	assert.NoError(t, json.Unmarshal(w.Body.Bytes(), &got))
	assert.Len(t, got, 1)

	mock.allErr = errors.New("db error")
	w = performRequest(r, "GET", "/achievements/all", nil, "")
	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

func TestListUserAchievements(t *testing.T) {
	mock := &mockUserSvc{
		unlockedAchievements: []services.Achievement{
			{ID: "u1", Title: "Y", IconURL: "", Unlocked: true},
		},
	}
	services.User = mock

	r := setupRouter()
	w := performRequest(r, "GET", "/achievements/user", nil, "user-1")
	assert.Equal(t, http.StatusOK, w.Code)

	var got []services.Achievement
	assert.NoError(t, json.Unmarshal(w.Body.Bytes(), &got))
	assert.Len(t, got, 1)

	mock.unlockedErr = errors.New("db error")
	w = performRequest(r, "GET", "/achievements/user", nil, "user-1")
	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

func TestRequestFriend(t *testing.T) {
	mock := &mockUserSvc{}
	services.User = mock
	r := setupRouter()

	w := performRequest(r, "POST", "/friends/request", gin.H{"email": "a@b.com"}, "u1")
	assert.Equal(t, http.StatusOK, w.Code)

	w = performRequest(r, "POST", "/friends/request", gin.H{"bad": "x"}, "u1")
	assert.Equal(t, http.StatusBadRequest, w.Code)

	mock.sendRequestErr = errors.New("fail")
	w = performRequest(r, "POST", "/friends/request", gin.H{"email": "a@b.com"}, "u1")
	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

func TestAcceptDeclineFriendRequest(t *testing.T) {
	mock := &mockUserSvc{}
	services.User = mock
	r := setupRouter()

	w := performRequest(r, "POST", "/friends/requests/r1/accept", nil, "u1")
	assert.Equal(t, http.StatusOK, w.Code)

	mock.acceptErr = errors.New("fail")
	w = performRequest(r, "POST", "/friends/requests/r1/accept", nil, "u1")
	assert.Equal(t, http.StatusInternalServerError, w.Code)

	mock.acceptErr = nil
	w = performRequest(r, "POST", "/friends/requests/r2/decline", nil, "u1")
	assert.Equal(t, http.StatusOK, w.Code)

	mock.declineErr = errors.New("fail")
	w = performRequest(r, "POST", "/friends/requests/r2/decline", nil, "u1")
	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

func TestListFriendRequests(t *testing.T) {
	mock := &mockUserSvc{
		pendingRequests: []services.Friend{{ID: "p1", Name: "Bar", Email: "bar@x"}},
	}
	services.User = mock
	r := setupRouter()

	w := performRequest(r, "GET", "/friends/requests", nil, "u1")
	assert.Equal(t, http.StatusOK, w.Code)

	var got []services.Friend
	assert.NoError(t, json.Unmarshal(w.Body.Bytes(), &got))
	assert.Len(t, got, 1)

	mock.pendingRequests = nil
	w = performRequest(r, "GET", "/friends/requests", nil, "u1")
	assert.Equal(t, http.StatusOK, w.Code)
	assert.JSONEq(t, "[]", w.Body.String())

	mock.pendingErr = errors.New("fail")
	w = performRequest(r, "GET", "/friends/requests", nil, "u1")
	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

func TestLogin(t *testing.T) {
	mock := &mockUserSvc{authToken: "tok"}
	services.User = mock
	r := setupRouter()

	// success with valid email
	w := performRequest(r, "POST", "/login", gin.H{"email": "a@b.com", "password": "p"}, "")
	assert.Equal(t, http.StatusOK, w.Code)
	var tok map[string]string
	assert.NoError(t, json.Unmarshal(w.Body.Bytes(), &tok))
	assert.Equal(t, "tok", tok["token"])

	// bad JSON
	w = performRequest(r, "POST", "/login", []byte("not-json"), "")
	assert.Equal(t, http.StatusBadRequest, w.Code)

	// invalid credentials (same valid email)
	mock.authErr = errors.New("fail")
	w = performRequest(r, "POST", "/login", gin.H{"email": "a@b.com", "password": "p"}, "")
	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestGetUpdateProfile(t *testing.T) {
	mock := &mockUserSvc{
		profile: services.UserProfile{ID: "u1", Name: "N", Email: "e"},
	}
	services.User = mock
	r := setupRouter()

	// GET profile success
	w := performRequest(r, "GET", "/profile", nil, "u1")
	assert.Equal(t, http.StatusOK, w.Code)
	var up services.UserProfile
	assert.NoError(t, json.Unmarshal(w.Body.Bytes(), &up))
	assert.Equal(t, "u1", up.ID)

	// GET profile error
	mock.profileErr = errors.New("db")
	w = performRequest(r, "GET", "/profile", nil, "u1")
	assert.Equal(t, http.StatusInternalServerError, w.Code)

	// PUT profile success
	mock.profileErr = nil
	w = performRequest(r, "PUT", "/profile", gin.H{"name": "X"}, "u1")
	assert.Equal(t, http.StatusOK, w.Code)

	// PUT profile error
	mock.updateErr = errors.New("fail")
	w = performRequest(r, "PUT", "/profile", gin.H{"name": "X"}, "u1")
	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

func TestRegister(t *testing.T) {
	mock := &mockUserSvc{
		createUserID: "u1",
		authToken:    "tok",
	}
	services.User = mock
	r := setupRouter()

	// success with valid email
	w := performRequest(r, "POST", "/register", gin.H{
		"name": "N", "email": "e@x.com", "password": "p",
	}, "")
	assert.Equal(t, http.StatusOK, w.Code)
	var out map[string]string
	assert.NoError(t, json.Unmarshal(w.Body.Bytes(), &out))
	assert.Equal(t, "tok", out["token"])

	// bad JSON (syntax)
	w = performRequest(r, "POST", "/register", []byte("not-json"), "")
	assert.Equal(t, http.StatusBadRequest, w.Code)

	// create error with valid email
	mock.createErr = errors.New("fail")
	w = performRequest(r, "POST", "/register", gin.H{
		"name": "N", "email": "e@x.com", "password": "p",
	}, "")
	assert.Equal(t, http.StatusInternalServerError, w.Code)

	// auth error
	mock.createErr = nil
	mock.authErr = errors.New("fail")
	w = performRequest(r, "POST", "/register", gin.H{
		"name": "N", "email": "e@x.com", "password": "p",
	}, "")
	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

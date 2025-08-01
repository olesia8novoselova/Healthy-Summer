// backend/internal/services/user.go
package services

import (
	//"database/sql"
	"errors"
	"log"
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"

	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/models"
	"github.com/timur-harin/sum25-go-flutter-course/backend/pkg/auth"
	"github.com/timur-harin/sum25-go-flutter-course/backend/pkg/db"
)

// ProfileUpdateInput matches your JSON input for updating profile.
type ProfileUpdateInput struct {
	Name      string   `json:"name"`
	AvatarURL string   `json:"avatarUrl"`
	Weight    *float64 `json:"weight"`
	Height    *float64 `json:"height"`
}

// UserProfile is what you return to the client.
type UserProfile struct {
	ID        string   `json:"id"`
	Name      string   `json:"name"`
	Email     string   `json:"email"`
	AvatarURL string   `json:"avatarUrl"`
	Weight    *float64 `json:"weight"`
	Height    *float64 `json:"height"`
}

// Friend for client responses.
type Friend struct {
	ID    string `json:"id"`
	Name  string `json:"name"`
	Email string `json:"email"`
}

// Achievement for client responses.
type Achievement struct {
	ID       string `json:"id"`
	Title    string `json:"title"`
	IconURL  string `json:"iconUrl"`
	Unlocked bool   `json:"unlocked"`
}

type ActivityStats struct {
	Date     string  `json:"date"`
	Calories float64 `json:"calories"`
	Duration float64 `json:"duration"`
}

type UserService interface {
	CreateUser(name, email, pass string) (string, error)
	Authenticate(email, pass string) (string, error)
	GetProfile(userID string) (UserProfile, error)
	UpdateProfile(userID string, in ProfileUpdateInput) error
	SendFriendRequest(userID, friendEmail string) error
	ListFriends(userID string) ([]Friend, error)
	AcceptFriendRequest(userID, requestID string) error
	DeclineFriendRequest(userID, requestID string) error
	ListPendingFriendRequests(userID string) ([]Friend, error)
	GetFriendIDs(userID string) ([]string, error)
	ListUnlockedAchievements(userID string) ([]Achievement, error)
	ListAllAchievements() ([]Achievement, error)
	AwardAchievementToUserID(userID, title string) error

	AddActivity(userID, activityType, name string, duration int, intensity string, calories int, location string) error
	ListActivities(userID string, filterType *string) ([]models.Activity, error)

	SetActivityGoal(userID string, goal int) error
	GetActivityGoal(userID string) (int, error)
	GetTodayCalories(userID string) (int, error)
	GetWeeklyStats(userID string) ([]ActivityStats, error)

	IDByEmail(email string) (string, error)
}

// userService holds the DB handle.
type userService struct {
}

// User is the exported singleton service.
var User UserService = &userService{}

// CreateUser inserts a new user (with hashed password) into the DB.
func (u *userService) CreateUser(name, email, pass string) (string, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(pass), bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}

	// model.User has db tags matching your users table.
	newUser := models.User{
		ID:           uuid.NewString(),
		Name:         name,
		Email:        email,
		PasswordHash: string(hash),
	}

	_, err = db.DB.NamedExec(`
		INSERT INTO users (id, name, email, password_hash, avatar_url)
		VALUES (:id, :name, :email, :password_hash, :avatar_url)
	`, &newUser)
	return newUser.ID, err
}

// Authenticate verifies credentials and returns a JWT on success.
func (u *userService) Authenticate(email, pass string) (string, error) {
	var user models.User
	err := db.DB.Get(&user, `
		SELECT id, password_hash 
		FROM users 
		WHERE email = $1
	`, email)
	if err != nil {
		return "", errors.New("invalid credentials")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(pass)); err != nil {
		return "", errors.New("invalid credentials")
	}

	// Generate JWT with your pkg/auth
	token, err := auth.GenerateToken(auth.Claims{UserID: user.ID})
	return token, err
}

// GetProfile loads the user's profile.
func (u *userService) GetProfile(userID string) (UserProfile, error) {
	var user models.User
	err := db.DB.Get(&user, `
		SELECT id, name, email, avatar_url, weight, height 
		FROM users 
		WHERE id = $1
	`, userID)
	if err != nil {
		return UserProfile{}, err
	}

	return UserProfile{
		ID:        user.ID,
		Name:      user.Name,
		Email:     user.Email,
		AvatarURL: user.AvatarURL,
		Weight:    user.Weight,
		Height:    user.Height,
	}, nil
}

// UpdateProfile updates name & email for the given user.
func (u *userService) UpdateProfile(userID string, in ProfileUpdateInput) error {
	_, err := db.DB.Exec(`
		UPDATE users 
		SET name = $1, avatar_url = $2, weight = $3, height = $4
		WHERE id = $5
	`, in.Name, in.AvatarURL, in.Weight, in.Height, userID)
	if err != nil {
		log.Printf("UpdateProfile error: %v", err)
	}
	return err
}

// SendFriendRequest creates a friend_request from the current user to another.
func (u *userService) SendFriendRequest(userID, friendEmail string) error {
	// 1) find recipient's ID
	var recipientID string
	err := db.DB.Get(&recipientID, `
		SELECT id 
		FROM users 
		WHERE email = $1
	`, friendEmail)
	if err != nil {
		return errors.New("user not found")
	}

	// 2) insert into friend_requests
	_, err = db.DB.Exec(`
		INSERT INTO friend_requests (id, requester_id, recipient_id, created_at)
		VALUES ($1, $2, $3, $4)
	`, uuid.NewString(), userID, recipientID, time.Now())
	return err
}

// ListFriends returns the list of accepted friends for a user.
// Assumes you have a 'friends' table populated elsewhere.
func (u *userService) ListFriends(userID string) ([]Friend, error) {
	var friends []Friend
	err := db.DB.Select(&friends, `
		SELECT u.id, u.name, u.email
		FROM friends f
		JOIN users u ON u.id = f.friend_id
		WHERE f.user_id = $1
	`, userID)
	return friends, err
}

// List only unlocked achievements for the user
func (u *userService) ListUnlockedAchievements(userID string) ([]Achievement, error) {
	var achievements []Achievement
	err := db.DB.Select(&achievements, `
        SELECT a.id, a.title, true as unlocked
        FROM achievements a
        JOIN user_achievements ua ON a.id = ua.achievement_id
        WHERE ua.user_id = $1
    `, userID)
	return achievements, err
}

// List all possible achievements (for the "all achievements" page)
func (u *userService) ListAllAchievements() ([]Achievement, error) {
	var achievements []Achievement
	err := db.DB.Select(&achievements, `
        SELECT a.id, a.title, false as unlocked
        FROM achievements a
    `)
	return achievements, err
}

func (u *userService) AwardAchievementToUserID(userID, title string) error {
	var achID string
	err := db.DB.Get(&achID, `SELECT id FROM achievements WHERE title = $1`, title)
	if err != nil {
		return err
	}
	// Check if already awarded to avoid duplicate
	var exists bool
	err = db.DB.Get(&exists, `SELECT EXISTS (
        SELECT 1 FROM user_achievements WHERE user_id = $1 AND achievement_id = $2
    )`, userID, achID)
	if err == nil && exists {
		return nil
	}
	// Insert award
	_, err = db.DB.Exec(`
        INSERT INTO user_achievements (user_id, achievement_id)
        VALUES ($1, $2)
    `, userID, achID)
	return err
}

func (s *userService) AddActivity(userID, activityType string, name string, duration int, intensity string, calories int, location string) error {
	_, err := db.DB.Exec(`
        INSERT INTO activities (user_id, type, name, duration, intensity, calories, location)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
    `, userID, activityType, name, duration, intensity, calories, location)
	return err
}

func (s *userService) ListActivities(userID string, filterType *string) ([]models.Activity, error) {
	var activities []models.Activity
	query := `SELECT * FROM activities WHERE user_id = $1`
	args := []interface{}{userID}
	if filterType != nil {
		query += ` AND type = $2`
		args = append(args, *filterType)
	}
	query += ` ORDER BY performed_at DESC`
	err := db.DB.Select(&activities, query, args...)
	return activities, err
}

func (s *userService) SetActivityGoal(userID string, goal int) error {
	_, err := db.DB.Exec(`
    INSERT INTO activity_goals (user_id, goal)
    VALUES ($1, $2)
    ON CONFLICT (user_id) DO UPDATE SET goal = EXCLUDED.goal, updated_at = now()
  `, userID, goal)
	return err
}

func (s *userService) GetActivityGoal(userID string) (int, error) {
	var goal int
	err := db.DB.Get(&goal, `SELECT goal FROM activity_goals WHERE user_id = $1`, userID)
	if err != nil {
		return 500, nil
	}
	return goal, nil
}

func (s *userService) GetTodayCalories(userID string) (int, error) {
	var total int
	err := db.DB.Get(&total, `
    SELECT COALESCE(SUM(calories), 0)
    FROM activities
    WHERE user_id = $1
      AND DATE(performed_at) = CURRENT_DATE
  `, userID)

	if err != nil {
		return 0, err
	}
	return total, nil
}

func (s *userService) GetWeeklyStats(userID string) ([]ActivityStats, error) {
	var stats []ActivityStats
	query := `
		SELECT
			TO_CHAR(performed_at::date, 'YYYY-MM-DD') AS date,
			COALESCE(SUM(calories), 0) AS calories,
			COALESCE(SUM(duration), 0) AS duration
		FROM activities
		WHERE user_id = $1
		  AND performed_at >= NOW() - INTERVAL '6 days'
		GROUP BY performed_at::date
		ORDER BY performed_at::date
	`
	if err := db.DB.Select(&stats, query, userID); err != nil {
		log.Printf("Error fetching weekly activity stats for user %s: %v", userID, err)
		return nil, err
	}
	return stats, nil
}

func (u *userService) AcceptFriendRequest(userID, requestID string) error {
	// 1. Check request exists and user is recipient
	var requesterID string
	err := db.DB.Get(&requesterID, `
		SELECT requester_id FROM friend_requests
		WHERE id = $1 AND recipient_id = $2
	`, requestID, userID)
	if err != nil {
		return errors.New("request not found")
	}

	// 2. Add both friends to the 'friends' table (bi-directional)
	_, err = db.DB.Exec(`
		INSERT INTO friends (user_id, friend_id) VALUES ($1, $2), ($2, $1)
	`, userID, requesterID)
	if err != nil {
		return err
	}

	// 3. Delete the request
	_, err = db.DB.Exec(`DELETE FROM friend_requests WHERE id = $1`, requestID)
	return err
}

func (u *userService) DeclineFriendRequest(userID, requestID string) error {
	// Just delete the request if user is recipient
	_, err := db.DB.Exec(`
		DELETE FROM friend_requests
		WHERE id = $1 AND recipient_id = $2
	`, requestID, userID)
	return err
}

// Returns friend requests where current user is recipient
func (u *userService) ListPendingFriendRequests(userID string) ([]Friend, error) {
	var requests []Friend
	err := db.DB.Select(&requests, `
		SELECT fr.id as id, u.name, u.email
		FROM friend_requests fr
		JOIN users u ON u.id = fr.requester_id
		WHERE fr.recipient_id = $1
	`, userID)
	return requests, err
}

func (u *userService) GetFriendIDs(userID string) ([]string, error) {
	var ids []string
	err := db.DB.Select(&ids, `
		SELECT friend_id
		FROM friends
		WHERE user_id = $1
	`, userID)
	return ids, err
}

func (s *userService) IDByEmail(email string) (string, error) {
	var id string
	err := db.DB.Get(&id, `SELECT id FROM users WHERE email=$1`, email)
	return id, err
}

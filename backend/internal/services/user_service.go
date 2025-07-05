// backend/internal/services/user.go
package services

import (
	"database/sql"
	"errors"
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"

	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/models"
	"github.com/timur-harin/sum25-go-flutter-course/backend/pkg/auth"
	"github.com/timur-harin/sum25-go-flutter-course/backend/pkg/db"
)

// ProfileUpdateInput matches your JSON input for updating profile.
type ProfileUpdateInput struct {
	Name  string `json:"name"`
	Email string `json:"email"`
}

// UserProfile is what you return to the client.
type UserProfile struct {
	ID        string `json:"id"`
	Name      string `json:"name"`
	Email     string `json:"email"`
	AvatarURL string `json:"avatarUrl"`
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

// userService holds the DB handle.
type userService struct {
	
}

// User is the exported singleton service.
var User = &userService{}

// CreateUser inserts a new user (with hashed password) into the DB.
func (u *userService) CreateUser(name, email, pass string) error {
	hash, err := bcrypt.GenerateFromPassword([]byte(pass), bcrypt.DefaultCost)
	if err != nil {
		return err
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
	return err
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
		SELECT id, name, email, avatar_url 
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
	}, nil
}

// UpdateProfile updates name & email for the given user.
func (u *userService) UpdateProfile(userID string, in ProfileUpdateInput) error {
	_, err := db.DB.Exec(`
		UPDATE users 
		SET name = $1, email = $2, updated_at = $3
		WHERE id = $4
	`, in.Name, in.Email, time.Now(), userID)
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

// AwardNextAchievement finds the next locked achievement and awards it.
func (u *userService) AwardNextAchievement(userID string) error {
	// 1) find next locked achievement
	var achID string
	err := db.DB.Get(&achID, `
		SELECT a.id
		FROM achievements a
		WHERE NOT EXISTS(
		  SELECT 1 
		  FROM user_achievements ua
		  WHERE ua.achievement_id = a.id AND ua.user_id = $1
		)
		ORDER BY a.created_at
		LIMIT 1
	`, userID)

	// no rows = nothing left to award
	if err == sql.ErrNoRows || errors.Is(err, sql.ErrNoRows) {
		return nil
	}
	if err != nil {
		return err
	}

	// 2) insert into user_achievements
	_, err = db.DB.Exec(`
		INSERT INTO user_achievements (id, user_id, achievement_id, unlocked_at)
		VALUES ($1, $2, $3, $4)
	`, uuid.NewString(), userID, achID, time.Now())
	return err
}

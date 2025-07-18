package models

import "time"

// FriendRequest represents an outbound invite in `friend_requests`.
type FriendRequest struct {
	ID          string    `db:"id" json:"id"`
	RequesterID string    `db:"requester_id" json:"requesterId"`
	RecipientID string    `db:"recipient_id" json:"recipientId"`
	CreatedAt   time.Time `db:"created_at" json:"createdAt"`
}

// Friend represents an accepted friendship in `friends`.
type Friend struct {
	ID        string    `db:"id" json:"id"`
	UserID    string    `db:"user_id" json:"userId"`
	FriendID  string    `db:"friend_id" json:"friendId"`
	CreatedAt time.Time `db:"created_at" json:"createdAt"`
}

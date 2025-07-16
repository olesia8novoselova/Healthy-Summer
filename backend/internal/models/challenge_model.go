package models

import "time"

type Challenge struct {
	ID        string    `db:"id"         json:"id"`
	CreatorID string    `db:"creator_id" json:"creator_id"`
	Type      string    `db:"type"       json:"type"`
	Target    int       `db:"target"    json:"target"`
	Title     string    `db:"title"     json:"title"`
	CreatedAt time.Time `db:"created_at" json:"created_at"`
}

type ChallengeParticipant struct {
	ChallengeID string `db:"challenge_id" json:"challenge_id"`
	UserID      string `db:"user_id"      json:"user_id"`
	Progress    int    `db:"progress"     json:"progress"`
	JoinedAt    string `db:"joined_at"    json:"joined_at"`
}
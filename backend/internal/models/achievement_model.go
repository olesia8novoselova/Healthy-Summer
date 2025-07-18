package models

import "time"

// Achievement is the master list in `achievements`.
type Achievement struct {
	ID        string    `db:"id" json:"id"`
	Title     string    `db:"title" json:"title"`
	CreatedAt time.Time `db:"created_at" json:"createdAt"`
}

// UserAchievement links users to unlocked achievements in `user_achievements`.
type UserAchievement struct {
	ID            string    `db:"id" json:"id"`
	UserID        string    `db:"user_id" json:"userId"`
	AchievementID string    `db:"achievement_id" json:"achievementId"`
	UnlockedAt    time.Time `db:"unlocked_at" json:"unlockedAt"`
}

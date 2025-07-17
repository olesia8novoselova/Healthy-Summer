package models

import "time"

// WorkoutSchedule matches the workout_schedules table.
//
// Weekday: Monday = 0 … Sunday = 6
// AtTime : stored as TIME (HH:MM:SS) in PostgreSQL, kept as string here.
type WorkoutSchedule struct {
	ID        string    `db:"id"         json:"id"`
	UserID    string    `db:"user_id"    json:"user_id"`
	Weekday   int       `db:"weekday"    json:"weekday"`
	AtTime    string    `db:"at_time"    json:"time"`   // "18:30:00"
	Title     string    `db:"title"      json:"title"`
	CreatedAt time.Time `db:"created_at" json:"created_at"`
}

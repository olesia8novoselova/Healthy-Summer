package models

import "time"

type Activity struct {
    ID          string    `db:"id" json:"id"`
    UserID      string    `db:"user_id" json:"userId"`
    Type        string    `db:"type" json:"type"`
    Name        string    `db:"name" json:"name"` 
    Duration    int       `db:"duration" json:"duration"`
    Intensity   string    `db:"intensity" json:"intensity"`
    Calories    int       `db:"calories" json:"calories"`
    Location    string    `db:"location" json:"location"`
    PerformedAt time.Time `db:"performed_at" json:"performedAt"`
}

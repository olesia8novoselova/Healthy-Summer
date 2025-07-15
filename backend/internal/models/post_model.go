package models

import "time"

type PostActivity struct {
    ID        string    `json:"id" db:"id"`
    UserID    string    `json:"userId" db:"user_id"`
    Type      string    `json:"type" db:"type"`
    Message   string    `json:"message" db:"message"`
    CreatedAt time.Time `json:"createdAt" db:"created_at"`
    UserName  string    `json:"user_name,omitempty" db:"user_name"`
}


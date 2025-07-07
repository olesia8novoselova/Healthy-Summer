package models

type User struct {
    ID           string    `db:"id" json:"id"`
    Name         string    `db:"name" json:"name"`
    Email        string    `db:"email" json:"email"`
    PasswordHash string    `db:"password_hash" json:"-"`
    AvatarURL    string    `db:"avatar_url" json:"avatarUrl"`
    Weight       *float64   `db:"weight" json:"weight"`
    Height       *float64   `db:"height" json:"height"`
}

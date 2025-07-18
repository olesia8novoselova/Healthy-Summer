package models

import "time"

type Message struct {
	ID         string    `db:"id" json:"id"`
	SenderID   string    `db:"sender_id" json:"sender_id"`
	ReceiverID string    `db:"receiver_id" json:"receiver_id"`
	Text       string    `db:"text" json:"text"`
	CreatedAt  time.Time `db:"created_at" json:"created_at"`
}

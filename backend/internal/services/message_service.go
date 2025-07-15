package services

import (
	//"time"

	//"github.com/google/uuid"
	//"github.com/lib/pq"
	"log"

	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/models"
	"github.com/timur-harin/sum25-go-flutter-course/backend/pkg/db"
)

type messageService struct{}

var Message = &messageService{}


// GetMessages retrieves chat history between the current user and a friend
func (s *messageService) GetMessages(userID, friendID string) ([]models.Message, error) {
  var msgs []models.Message
  query := `
    SELECT id, sender_id, receiver_id, text, created_at
    FROM messages
    WHERE (sender_id=$1 AND receiver_id=$2) OR (sender_id=$2 AND receiver_id=$1)
    ORDER BY created_at
  `
  err := db.DB.Select(&msgs, query, userID, friendID)
  return msgs, err
}

// SendMessage saves a new message and broadcasts it via WebSocket
func (s *messageService) SendMessage(msg models.Message) error {
    log.Printf("[MessageService] Saving to DB: %+v", msg)
    _, err := db.DB.Exec(
        `INSERT INTO messages (id, sender_id, receiver_id, text, created_at) VALUES ($1,$2,$3,$4,$5)`,
        msg.ID, msg.SenderID, msg.ReceiverID, msg.Text, msg.CreatedAt,
    )
    if err != nil {
        log.Printf("[MessageService] DB ERROR: %v", err)
        return err
    }

    // Broadcast to both sender and recipient!
    BroadcastMsg(msg)
    return nil
}

func BroadcastMsg(msg models.Message) {
    log.Printf("[MessageService] Broadcasting to: %v and %v | msg: %v", msg.ReceiverID, msg.SenderID, msg.Text)
    ActivityHub.Broadcast(ActivityMessage{
        RecipientIDs: []string{msg.ReceiverID, msg.SenderID},
        Data:         msg,
    })
}

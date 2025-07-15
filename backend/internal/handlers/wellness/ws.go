package wellness

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/services"
	"github.com/timur-harin/sum25-go-flutter-course/backend/pkg/auth"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

func ActivitySocket(c *gin.Context) {
	tokenStr := c.Query("token")
	if tokenStr == "" {
		c.Writer.WriteHeader(http.StatusUnauthorized)
		return
	}
	log.Println("Token received:", tokenStr)

	claims, err := auth.ParseToken(tokenStr)
	if err != nil {
		log.Println("JWT Parse error:", err)
		c.Writer.WriteHeader(http.StatusUnauthorized)
		return
	}
	userID := claims.UserID

	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Println("Failed to upgrade connection: ", err)
		return
	}
	services.ActivityHub.Register(userID, conn)
	defer services.ActivityHub.Unregister(userID, conn)

	type ChatMessage struct {
		From      string `json:"from"`
		To        string `json:"to"`
		Text      string `json:"text"`
		Timestamp string `json:"timestamp"`
	}

	for {
		_, msgBytes, err := conn.ReadMessage()
		if err != nil {
			log.Println("WebSocket read error:", err)
			break
		}

		var msg ChatMessage
		if err := json.Unmarshal(msgBytes, &msg); err != nil {
			log.Println("Failed to unmarshal chat message:", err)
			continue
		}

		log.Printf("Received chat message: %+v\n", msg)

		// Save message to DB here if needed

		// Broadcast to recipient and sender (for echo)
		services.ActivityHub.Broadcast(services.ActivityMessage{
			RecipientIDs: []string{msg.To, msg.From},
			Data:         msg,
		})
	}
	log.Println("Connection closed")
}

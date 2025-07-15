package wellness

import (
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/models"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/services"
	"github.com/timur-harin/sum25-go-flutter-course/backend/pkg/auth"
)

var wsUpgrader = websocket.Upgrader{
  ReadBufferSize:  1024,
  WriteBufferSize: 1024,
  CheckOrigin: func(r *http.Request) bool { return true },
}

// GetChatList returns the list of the user's friends
func GetChatList(c *gin.Context) {
  userID := c.GetString("userID")
  ids, _ := services.User.GetFriendIDs(userID)
  friends := make([]map[string]string, 0, len(ids))
  for _, fid := range ids {
    profile, err := services.User.GetProfile(fid)
    if err != nil {
		log.Println("Failed to get profile: ", err)
        return 
    }
    name := profile.Name
    friends = append(friends, map[string]string{"id": fid, "name": name})
}
	if friends == nil {
		friends = []map[string]string{}
	}
	
  c.JSON(http.StatusOK, friends)
}

// GetMessages loads chat history with a friend
func GetMessages(c *gin.Context) {
  userID := c.GetString("userID")
  friendID := c.Param("friendId")
  msgs, err := services.Message.GetMessages(userID, friendID)
  if err != nil {
	log.Println("Failed to get messages: ", err)
    c.JSON(http.StatusInternalServerError, gin.H{"error": "cannot load messages"})
    return
  }
  c.JSON(http.StatusOK, msgs)
}

// PostMessage handles sending a new chat message
func PostMessage(c *gin.Context) {
  userID := c.GetString("userID")
  var req struct {
    To   string `json:"to" binding:"required"`
    Text string `json:"text" binding:"required"`
  }
  if err := c.ShouldBindJSON(&req); err != nil {
    c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
    return
  }
  msg := models.Message{
    ID:         uuid.NewString(),
    SenderID:   userID,
    ReceiverID: req.To,
    Text:       req.Text,
    CreatedAt:  time.Now(),
  }
  log.Printf("[REST] Incoming POST message: from %v to %v, text: %v", userID, req.To, req.Text)

  if err := services.Message.SendMessage(msg); err != nil {
	log.Println("Failed to send message: ", err)
    c.JSON(http.StatusInternalServerError, gin.H{"error": "cannot send message"})
    return
  }
  log.Println("[REST] Message sent")
  c.JSON(http.StatusOK, msg)
}

// WebSocketHandler upgrades HTTP to WebSocket for real-time messaging
func WebSocketHandler(c *gin.Context) {
    tokenStr := c.Query("token")
    if tokenStr == "" {
        log.Println("[WS] Missing token query param")
        c.Writer.WriteHeader(http.StatusUnauthorized)
        return
    }
    claims, err := auth.ParseToken(tokenStr)
    if err != nil {
        log.Printf("[WS] Invalid token: %v", err)
        c.Writer.WriteHeader(http.StatusUnauthorized)
        return
    }
    userID := claims.UserID

    log.Printf("[WS] Attempt WebSocket connect for user: %v", userID)
    conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
    if err != nil {
        log.Println("[WS] Failed to upgrade connection: ", err)
        return
    }
    log.Printf("[WS] WebSocket CONNECTED: %v", userID)
    services.ActivityHub.Register(userID, conn)
    defer func() {
        services.ActivityHub.Unregister(userID, conn)
        log.Printf("[WS] WebSocket DISCONNECTED: %v", userID)
    }()

    for {
        var incoming models.Message
        if err := conn.ReadJSON(&incoming); err != nil {
            log.Printf("[WS] %v connection closed or read error: %v", userID, err)
            break
        }
        log.Printf("[WS] Message RECEIVED from client: %+v", incoming)
        // Overwrite sender and timestamp
        if incoming.SenderID == "" {
            incoming.SenderID = userID
        }

        incoming.ID = uuid.NewString()
        incoming.SenderID = userID
        incoming.CreatedAt = time.Now()
        if err := services.Message.SendMessage(incoming); err != nil {
            log.Printf("[WS] Error saving/sending: %v", err)
        }
    }
    log.Printf("[WS] Connection closed for user: %v", userID)
}
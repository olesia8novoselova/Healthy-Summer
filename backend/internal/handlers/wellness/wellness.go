package wellness

import (
	"net/http"
	"time"
	"log"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/models"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/services"
	"github.com/timur-harin/sum25-go-flutter-course/backend/pkg/db"
)



func PostActivity(c *gin.Context) {
	userID := c.GetString("userID")
	var req struct {
		Type    string `json:"type" binding:"required"`
		Message string `json:"message" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	activity := models.PostActivity{
    ID:        uuid.NewString(),
    UserID:    userID,
    Type:      req.Type,
    Message:   req.Message,
    CreatedAt: time.Now(),
}

	// Save to DB
	_, err := db.DB.Exec(`
        INSERT INTO post_activities (id, user_id, type, message, created_at)
        VALUES ($1, $2, $3, $4, $5)
    `, activity.ID, activity.UserID, activity.Type, activity.Message, activity.CreatedAt)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "cannot save activity"})
		return
	}

	// WebSocket push to friends
	go services.NotifyFriendsOfActivity(userID, activity)

	c.Status(http.StatusOK)
}

func GetFriendsActivities(c *gin.Context) {
    userID := c.GetString("userID")
    friendIDs, _ := services.User.GetFriendIDs(userID)
    activities, err := services.Post.GetFriendsActivities(userID, friendIDs, 10)
    if err != nil {
		log.Printf("Failed to get friends activities: %v", err)
        c.JSON(http.StatusInternalServerError, gin.H{"error": "cannot load activities"})
        return
    }
	if activities == nil {
		activities = []models.PostActivity{}
	}
    c.JSON(http.StatusOK, activities)
}
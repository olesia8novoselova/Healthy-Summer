package user

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/services"
)

type friendRequest struct {
	Email string `json:"email" binding:"required,email"`
}

func RequestFriend(c *gin.Context) {
	userID := c.GetString("userID")
	var req friendRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := services.User.SendFriendRequest(userID, req.Email); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "cannot send request"})
		return
	}
	c.Status(http.StatusOK)
}

func ListFriends(c *gin.Context) {
	userID := c.GetString("userID")
	list, err := services.User.ListFriends(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "cannot load friends"})
		return
	}
	c.JSON(http.StatusOK, list)
}

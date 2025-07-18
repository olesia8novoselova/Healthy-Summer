package user

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/services"
)

type Friend struct {
	ID    string `json:"id"`
	Name  string `json:"name"`
	Email string `json:"email"`
}

type friendRequest struct {
	Email string `json:"email" binding:"required,email"`
}

func RequestFriend(c *gin.Context) {
	userID := c.GetString("userID")
	log.Println("Requesting friend for user", userID)
	var req friendRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := services.User.SendFriendRequest(userID, req.Email); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "cannot send request"})
		return
	}
	log.Println("Friend request sent to", req.Email)
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

func AcceptFriendRequest(c *gin.Context) {
	userID := c.GetString("userID")
	requestID := c.Param("id")
	log.Println("Accepting friend request for user", userID)
	err := services.User.AcceptFriendRequest(userID, requestID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "cannot accept request"})
		return
	}
	log.Println("Friend request accepted for user", userID)
	c.Status(http.StatusOK)
}

func DeclineFriendRequest(c *gin.Context) {
	userID := c.GetString("userID")
	requestID := c.Param("id")
	err := services.User.DeclineFriendRequest(userID, requestID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "cannot decline request"})
		return
	}
	c.Status(http.StatusOK)
}

func ListFriendRequests(c *gin.Context) {
	userID := c.GetString("userID")
	log.Println("Listing friend requests for user", userID)
	list, err := services.User.ListPendingFriendRequests(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "cannot load requests"})
		return
	}
	log.Println("Returning", len(list), "friend requests")
	if list == nil {
		c.JSON(http.StatusOK, []Friend{})
	} else {
		c.JSON(http.StatusOK, list)
	}

}

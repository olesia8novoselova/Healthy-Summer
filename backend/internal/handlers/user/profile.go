package user

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/services"
)

func GetProfile(c *gin.Context) {
	userID := c.GetString("userID") // populated by your auth middleware
	profile, err := services.User.GetProfile(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "cannot load profile"})
		return
	}
	c.JSON(http.StatusOK, profile)
}

func UpdateProfile(c *gin.Context) {
	userID := c.GetString("userID")
	var input services.ProfileUpdateInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := services.User.UpdateProfile(userID, input); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "cannot update"})
		return
	}
	c.Status(http.StatusOK)
}

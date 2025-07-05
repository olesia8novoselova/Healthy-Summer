package user

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/services"
)

func AwardAchievement(c *gin.Context) {
	userID := c.GetString("userID")
	// You could accept a payload here if needed; for simplicity, we'll auto‐award next achievement
	if err := services.User.AwardNextAchievement(userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "cannot award"})
		return
	}
	c.Status(http.StatusOK)
}

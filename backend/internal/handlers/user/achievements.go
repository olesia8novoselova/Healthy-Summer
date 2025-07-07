package user

import (
	"log"
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

func ListAllAchievements(c *gin.Context) {
	log.Printf("Listing all achievements for user")
    achievements, err := services.User.ListAllAchievements()
    if err != nil {
		log.Printf("Failed to list all achievements: %v", err)
        c.JSON(http.StatusInternalServerError, gin.H{"error": "cannot load achievements"})
        return
    }
	log.Printf("Returning %d achievements", len(achievements))
    c.JSON(http.StatusOK, achievements)
}

// Returns only unlocked achievements for the logged-in user
func ListUserAchievements(c *gin.Context) {
    userID := c.GetString("userID")
	log.Printf("Listing achievements for user %s", userID)
    achievements, err := services.User.ListUnlockedAchievements(userID)
    if err != nil {
		log.Printf("Failed to list user achievements: %v", err)
        c.JSON(http.StatusInternalServerError, gin.H{"error": "cannot load achievements"})
        return
    }
	log.Printf("Returning %d achievements for user %s", len(achievements), userID)
    c.JSON(http.StatusOK, achievements)
}
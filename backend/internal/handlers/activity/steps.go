package activity

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/services"
)

func AddSteps(c *gin.Context) {
    userID := c.GetString("userID")
    var req struct {
        Steps int `json:"steps"`
    }
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    // Save steps for today
    if err := services.Step.AddOrUpdateSteps(userID, req.Steps); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to save steps"})
        return
    }

    _ = services.Step.AwardStepAchievements(userID)

    c.Status(http.StatusOK)
}


func GetStepStats(c *gin.Context) {
    userID := c.GetString("userID")
    goal := 10000
    stats, err := services.Step.GetStepStats(userID, goal)
    if err != nil {
        c.JSON(500, gin.H{"error": "failed to get step stats"})
        return
    }
    c.JSON(200, stats)
}

func GetStepAnalytics(c *gin.Context) {
    userID := c.GetString("userID")
    days := 30
    if d := c.Query("days"); d != "" {
        if n, err := strconv.Atoi(d); err == nil && n > 0 && n <= 90 {
            days = n
        }
    }
    result, err := services.Step.GetStepAnalytics(userID, days)
    if err != nil {
        c.JSON(500, gin.H{"error": "failed to get analytics"})
        return
    }
    c.JSON(200, result)
}

func SetStepGoal(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	var input struct {
		Goal int `json:"goal"`
	}
	if err := c.BindJSON(&input); err != nil {
		c.JSON(400, gin.H{"error": "Invalid body"})
		return
	}
	err := services.Step.SetStepGoal(userID, input.Goal)
	if err != nil {
		c.JSON(500, gin.H{"error": "Failed to set goal"})
		return
	}
	c.JSON(200, gin.H{"success": true})
}

func GetStepGoal(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	goal, err := services.Step.GetStepGoal(userID)
	if err != nil {
		c.JSON(500, gin.H{"error": "Failed to get goal"})
		return
	}
	c.JSON(200, gin.H{"goal": goal})
}

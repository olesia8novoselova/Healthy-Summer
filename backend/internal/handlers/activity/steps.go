package activity

import (
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/services"
)

type StepService interface {
	AddOrUpdateSteps(userID string, steps int) error
	AwardStepAchievements(userID string) error
	GetStepStats(userID string, goal int) (services.StepStats, error)
	GetStepAnalytics(userID string, days int) ([]services.StepDay, error)
	SetStepGoal(userID string, goal int) error
	GetStepGoal(userID string) (int, error)
}

var stepService StepService = services.Step

func ResetStepService(svc StepService) {
	stepService = svc
}

// AddSteps saves today's steps and awards achievements.
func AddSteps(c *gin.Context) {
	userID := c.GetString("userID")
	var req struct {
		Steps int `json:"steps"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := stepService.AddOrUpdateSteps(userID, req.Steps); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to save steps"})
		return
	}

	_ = stepService.AwardStepAchievements(userID)

	if err := challengeService.BumpProgress(userID, "steps", req.Steps); err != nil {
		log.Printf("[Challenge] bump steps: %v", err)
	}

	c.Status(http.StatusOK)
}

// GetStepStats returns today's and aggregated step stats.
func GetStepStats(c *gin.Context) {
	userID := c.GetString("userID")
	const defaultGoal = 10000

	stats, err := stepService.GetStepStats(userID, defaultGoal)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to get step stats"})
		return
	}

	c.JSON(http.StatusOK, stats)
}

// GetStepAnalytics returns the last N days of step data.
func GetStepAnalytics(c *gin.Context) {
	userID := c.GetString("userID")
	days := 30
	if d := c.Query("days"); d != "" {
		if n, err := strconv.Atoi(d); err == nil && n > 0 && n <= 90 {
			days = n
		}
	}

	result, err := stepService.GetStepAnalytics(userID, days)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to get analytics"})
		return
	}

	c.JSON(http.StatusOK, result)
}

// SetStepGoal updates the user's daily step goal.
func SetStepGoal(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	var input struct {
		Goal int `json:"goal"`
	}
	if err := c.BindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid body"})
		return
	}

	if err := stepService.SetStepGoal(userID, input.Goal); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to set goal"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true})
}

// GetStepGoal fetches the user's current daily step goal.
func GetStepGoal(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	goal, err := stepService.GetStepGoal(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get goal"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"goal": goal})
}

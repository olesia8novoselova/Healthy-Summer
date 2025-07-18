package activity

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/models"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/services"
)

type UserService interface {
	AddActivity(userID, typ, name string, duration int, intensity string, calories int, location string) error
	ListActivities(userID string, filter *string) ([]models.Activity, error)
	SetActivityGoal(userID string, goal int) error
	GetActivityGoal(userID string) (int, error)
	GetTodayCalories(userID string) (int, error)
	GetWeeklyStats(userID string) ([]services.ActivityStats, error)
}

var userService UserService = services.User

func ResetUserService(svc UserService) {
	userService = svc
}

type ChallengeService interface {
	BumpProgress(userID, metric string, amount int) error
}

var challengeService ChallengeService = services.Challenge

func ResetChallengeService(svc ChallengeService) {
	challengeService = svc
}

func AddActivity(c *gin.Context) {
	userID := c.GetString("userID")
	var req struct {
		Type      string `json:"type"`
		Name      string `json:"name"`
		Duration  int    `json:"duration"`
		Intensity string `json:"intensity"`
		Calories  int    `json:"calories"`
		Location  string `json:"location"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := userService.AddActivity(userID, req.Type, req.Name, req.Duration, req.Intensity, req.Calories, req.Location); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to log activity"})
		return
	}
	if err := challengeService.BumpProgress(userID, "workouts", 1); err != nil {
		log.Printf("[Challenge] bump workouts: %v", err)
	}
	c.Status(http.StatusOK)
}

func ListActivities(c *gin.Context) {
	userID := c.GetString("userID")
	log.Printf("Listing activities for user: %s", userID)

	filterType := c.Query("type")
	var filter *string
	if filterType != "" {
		filter = &filterType
	}
	activities, err := userService.ListActivities(userID, filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch activities"})
		return
	}
	c.JSON(http.StatusOK, activities)
}

func SetActivityGoal(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	var input struct {
		Goal int `json:"goal"`
	}
	if err := c.BindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid body"})
		return
	}
	if err := userService.SetActivityGoal(userID, input.Goal); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to set goal"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true})
}

func GetActivityGoal(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	goal, err := userService.GetActivityGoal(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get goal"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"goal": goal})
}

func GetTodayActivityCalories(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	total, err := userService.GetTodayCalories(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch calories"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"calories": total})
}

func GetWeeklyActivityStats(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	stats, err := userService.GetWeeklyStats(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to get weekly activity stats"})
		return
	}
	c.JSON(http.StatusOK, stats)
}

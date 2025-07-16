package activity

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/services"
)

type ActivityStats struct {
	Date     string  `json:"date"`
	Calories float64 `json:"calories"`
	Duration float64 `json:"duration"`
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
    if err := services.User.AddActivity(userID, req.Type, req.Name, req.Duration, req.Intensity, req.Calories, req.Location); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to log activity"})
        return
    }

    if err := services.Challenge.
        BumpProgress(userID, "workouts", 1); err != nil {
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
    activities, err := services.User.ListActivities(userID, filter)
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
    c.JSON(400, gin.H{"error": "Invalid body"})
    return
  }
  err := services.User.SetActivityGoal(userID, input.Goal)
  if err != nil {
    c.JSON(500, gin.H{"error": "Failed to set goal"})
    return
  }
  c.JSON(200, gin.H{"success": true})
}

func GetActivityGoal(c *gin.Context) {
  userID := c.MustGet("userID").(string)
  goal, err := services.User.GetActivityGoal(userID)
  if err != nil {
    c.JSON(500, gin.H{"error": "Failed to get goal"})
    return
  }
  c.JSON(200, gin.H{"goal": goal})
}

func GetTodayActivityCalories(c *gin.Context) {
  userID := c.MustGet("userID").(string)

  total, err := services.User.GetTodayCalories(userID)
  if err != nil {
    c.JSON(500, gin.H{"error": "Failed to fetch calories"})
    return
  }

  c.JSON(200, gin.H{"calories": total})
}
func GetWeeklyActivityStats(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	stats, err := services.User.GetWeeklyStats(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to get weekly activity stats"})
		return
	}
	c.JSON(http.StatusOK, stats)
}
package activity

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/services"
)

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
    c.Status(http.StatusOK)
}

func ListActivities(c *gin.Context) {
    userID := c.GetString("userID")
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

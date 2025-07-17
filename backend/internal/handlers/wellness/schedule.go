package wellness

import (
    "net/http"
    "time"

    "github.com/gin-gonic/gin"
    "github.com/google/uuid"
    "github.com/timur-harin/sum25-go-flutter-course/backend/internal/services"
)

type workoutReq struct {
    Weekday int    `json:"weekday"` // 0..6
    At      string `json:"time"`    // "18:30"
    Title   string `json:"title"`
}

func AddWorkout(c *gin.Context) {
    userID := c.GetString("userID")
    var req workoutReq
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    t, err := time.Parse("15:04", req.At)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "invalid time"})
        return
    }
    err = services.Schedule.AddWorkout(
        uuid.NewString(), userID, req.Weekday, t.Format("15:04:05"), req.Title)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    c.Status(http.StatusOK)
}

func ListWorkouts(c *gin.Context) {
    userID := c.GetString("userID")
    l, _ := services.Schedule.ListWorkouts(userID)
    c.JSON(http.StatusOK, l)
}

func DeleteWorkout(c *gin.Context) {
    userID := c.GetString("userID")
    id := c.Param("id")
    if err := services.Schedule.DeleteWorkout(userID, id); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    c.Status(http.StatusOK)
}

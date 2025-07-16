package wellness

import (

	"github.com/gin-gonic/gin"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/models"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/services"
)

type createReq struct {
  Title  string `json:"title"   binding:"required"`
  Type   string `json:"type"    binding:"required,oneof=steps workouts calories"`
  Target int    `json:"target"  binding:"required,min=1"`
  Participants  []string `json:"participants"   binding:"required"`
}

func CreateChallenge(c *gin.Context) {
    userID := c.GetString("userID")
    var req struct {
        Title        string   `json:"title" binding:"required"`
        Type         string   `json:"type"  binding:"required"`
        Target       int      `json:"target" binding:"required"`
        Participants []string `json:"participants"`
    }
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }

    ch, err := services.Challenge.Create(
        userID, req.Title, req.Type, req.Target, req.Participants,
    )
    if err != nil {
        c.JSON(500, gin.H{"error": "cannot create"})
        return
    }
    c.JSON(201, ch)
}

func JoinChallenge(c *gin.Context) {
  userID := c.GetString("userID")
  chID   := c.Param("id")
  if err := services.Challenge.Join(chID, userID); err != nil {
    c.JSON(500, gin.H{"error":"cannot join"}); return
  }
  c.Status(200)
}

func ListChallenges(c *gin.Context) {
    userID := c.GetString("userID")
    list, err := services.Challenge.ListForUser(userID)
    if err != nil {
        c.JSON(500, gin.H{"error": "cannot load"})
        return
    }
    if list == nil {
        list = []models.Challenge{}
    }
    c.JSON(200, list)
}



func GetLeaderboard(c *gin.Context) {
  chID := c.Param("id")
  lb, err := services.Challenge.Leaderboard(chID)
  if err != nil { c.JSON(500, gin.H{"error":"cannot lb"}); return }
  c.JSON(200, lb)
}


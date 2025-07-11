package nutrition

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/services"
)
type waterLogRequest struct {
	Amount int `json:"amount"`
}

func AddMeal(c *gin.Context) {
	userID := c.GetString("userID")
	var req services.Meal
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := services.Nutrition.AddMeal(userID, req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to add meal"})
		return
	}
	c.Status(http.StatusOK)
}

func ListMeals(c *gin.Context) {
	userID := c.GetString("userID")
	meals, err := services.Nutrition.ListMeals(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch meals"})
		return
	}
	if meals == nil {
		meals = []services.Meal{services.Meal{}}
	}
	c.JSON(http.StatusOK, meals)
}

func GetNutritionStats(c *gin.Context) {
	userID := c.GetString("userID")
	stats, err := services.Nutrition.GetNutritionStats(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch stats"})
		return
	}
	c.JSON(http.StatusOK, stats)
}

func GetWeeklyNutritionStats(c *gin.Context) {
	userID := c.MustGet("userID").(string)

	stats, err := services.Nutrition.GetWeeklyNutritionStats(userID)
	if err != nil {
		log.Println("Weekly stats error:", err) 
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to get weekly stats"})
		return
	}
	c.JSON(http.StatusOK, stats)
}

func AddWaterLog(c *gin.Context) {
	userID := c.MustGet("userID").(string)

	var req waterLogRequest
	if err := c.ShouldBindJSON(&req); err != nil || req.Amount <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid amount"})
		return
	}

	if err := services.Nutrition.AddWaterLog(userID, req.Amount); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to log water"})
		return
	}
	c.Status(http.StatusOK)
}

func GetTodayWaterStats(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	stats, err := services.Nutrition.GetTodayWaterStats(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to get water stats"})
		return
	}
	c.JSON(http.StatusOK, stats)
}

func GetWeeklyWaterStats(c *gin.Context) {
	userIDRaw, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized: userID missing"})
		return
	}

	userID, ok := userIDRaw.(string)
	if !ok || userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized: invalid userID"})
		return
	}

	stats, err := services.Nutrition.GetWeeklyWaterStats(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to get weekly water stats"})
		return
	}
	c.JSON(http.StatusOK, stats)
}

func SetWaterGoal(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	var input struct {
		GoalML int `json:"goal_ml"`
	}
	if err := c.BindJSON(&input); err != nil {
		c.JSON(400, gin.H{"error": "Invalid body"})
		return
	}
	err := services.Nutrition.SetWaterGoal(userID, input.GoalML)
	if err != nil {
		c.JSON(500, gin.H{"error": "Failed to set goal"})
		return
	}
	c.JSON(200, gin.H{"success": true})
}

func GetWaterGoal(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	goal, err := services.Nutrition.GetWaterGoal(userID)
	if err != nil {
		c.JSON(500, gin.H{"error": "Failed to get goal"})
		return
	}
	c.JSON(200, gin.H{"goal_ml": goal})
}

func SetCalorieGoal(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	var input struct {
		Goal int `json:"goal"`
	}
	if err := c.BindJSON(&input); err != nil {
		c.JSON(400, gin.H{"error": "Invalid body"})
		return
	}
	err := services.Nutrition.SetCalorieGoal(userID, input.Goal)
	if err != nil {
		c.JSON(500, gin.H{"error": "Failed to set goal"})
		return
	}
	c.JSON(200, gin.H{"success": true})
}

func GetCalorieGoal(c *gin.Context) {
	userID := c.MustGet("userID").(string)
	goal, err := services.Nutrition.GetCalorieGoal(userID)
	if err != nil {
		c.JSON(500, gin.H{"error": "Failed to get goal"})
		return
	}
	c.JSON(200, gin.H{"goal": goal})
}


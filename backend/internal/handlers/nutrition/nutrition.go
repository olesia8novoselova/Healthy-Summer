package nutrition

import (
	"net/http"
	"github.com/gin-gonic/gin"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/services"
)

// POST /api/meals
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

// GET /api/meals
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

// GET /api/nutrition/stats
func GetNutritionStats(c *gin.Context) {
	userID := c.GetString("userID")
	stats, err := services.Nutrition.GetNutritionStats(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch stats"})
		return
	}
	c.JSON(http.StatusOK, stats)
}

package services

import (
	"time"
	"github.com/timur-harin/sum25-go-flutter-course/backend/pkg/db"
)

type Meal struct {
	ID          string    `db:"id" json:"id"`
	UserID      string    `db:"user_id" json:"user_id"`
	FdcID       int       `db:"fdc_id" json:"fdcId"`
	Description string    `db:"description" json:"description"`
	Calories    float64   `db:"calories" json:"calories"`
	Protein     float64   `db:"protein" json:"protein"`
	Fat         float64   `db:"fat" json:"fat"`
	Carbs       float64   `db:"carbs" json:"carbs"`
	Quantity    float64   `db:"quantity" json:"quantity"`
	Unit        string    `db:"unit" json:"unit"`
	CreatedAt   time.Time `db:"created_at" json:"created_at"`
}

type NutritionStats struct {
	Calories float64 `json:"calories"`
	Protein  float64 `json:"protein"`
	Fat      float64 `json:"fat"`
	Carbs    float64 `json:"carbs"`
	Goal     float64 `json:"goal"` 
}

type nutritionService struct{}

var Nutrition = &nutritionService{}

func (s *nutritionService) AddMeal(userID string, meal Meal) error {
	_, err := db.DB.Exec(`
		INSERT INTO meals (user_id, fdc_id, description, calories, protein, fat, carbs, quantity, unit)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
	`, userID, meal.FdcID, meal.Description, meal.Calories, meal.Protein, meal.Fat, meal.Carbs, meal.Quantity, meal.Unit)
	return err
}

func (s *nutritionService) ListMeals(userID string) ([]Meal, error) {
	var meals []Meal
	err := db.DB.Select(&meals, `
		SELECT * FROM meals WHERE user_id = $1 ORDER BY created_at DESC
	`, userID)
	return meals, err
}

func (s *nutritionService) GetNutritionStats(userID string) (NutritionStats, error) {
	today := time.Now().Format("2006-01-02")
	var stats NutritionStats
	err := db.DB.Get(&stats, `
		SELECT
			COALESCE(SUM(calories),0) as calories,
			COALESCE(SUM(protein),0) as protein,
			COALESCE(SUM(fat),0) as fat,
			COALESCE(SUM(carbs),0) as carbs,
			2000 as goal -- you can personalize this
		FROM meals
		WHERE user_id = $1 AND created_at::date = $2
	`, userID, today)
	return stats, err
}

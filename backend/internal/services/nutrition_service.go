package services

import (
	//"log"
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
	Date     string  `db:"date" json:"date"`
	Calories float64 `json:"calories"`
	Protein  float64 `json:"protein"`
	Fat      float64 `json:"fat"`
	Carbs    float64 `json:"carbs"`
	Goal     float64 `json:"goal"`
}

type WaterLog struct {
	ID        string    `db:"id" json:"id"`
	UserID    string    `db:"user_id" json:"user_id"`
	AmountML  int       `db:"amount_ml" json:"amount_ml"`
	CreatedAt time.Time `db:"created_at" json:"created_at"`
}

type DailyWaterStats struct {
	Date    string `db:"date" json:"date"`
	TotalML int    `db:"total_ml" json:"total_ml"`
	GoalML  int    `db:"goal_ml" json:"goal_ml"`
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
	var stats NutritionStats
	err := db.DB.Get(&stats, `
		SELECT
			TO_CHAR(CURRENT_DATE, 'YYYY-MM-DD') as date,
			COALESCE(SUM(calories),0) as calories,
			COALESCE(SUM(protein),0) as protein,
			COALESCE(SUM(fat),0) as fat,
			COALESCE(SUM(carbs),0) as carbs
		FROM meals
		WHERE user_id = $1 AND created_at::date = CURRENT_DATE
	`, userID)
	if err != nil {
		return stats, err
	}

	goal, _ := s.GetCalorieGoal(userID)
	stats.Goal = float64(goal)

	return stats, nil
}

func (s *nutritionService) GetWeeklyNutritionStats(userID string) ([]NutritionStats, error) {
	var stats []NutritionStats
	err := db.DB.Select(&stats, `
		SELECT
			TO_CHAR(DATE(created_at), 'YYYY-MM-DD') as date,
			COALESCE(SUM(calories), 0) as calories,
			COALESCE(SUM(protein), 0) as protein,
			COALESCE(SUM(fat), 0) as fat,
			COALESCE(SUM(carbs), 0) as carbs
		FROM meals
		WHERE user_id = $1 AND created_at >= NOW() - INTERVAL '6 days'
		GROUP BY DATE(created_at)
		ORDER BY DATE(created_at)
	`, userID)
	if err != nil {
		return stats, err
	}

	goal, _ := s.GetCalorieGoal(userID)
	for i := range stats {
		stats[i].Goal = float64(goal)
	}

	return stats, nil
}

func (s *nutritionService) AddWaterLog(userID string, amount int) error {
	_, err := db.DB.Exec(`
		INSERT INTO water_logs (user_id, amount_ml) VALUES ($1, $2)
	`, userID, amount)
	return err
}

func (s *nutritionService) GetTodayWaterStats(userID string) (DailyWaterStats, error) {
	var stats DailyWaterStats
	goal, _ := s.GetWaterGoal(userID)

	err := db.DB.Get(&stats, `
		SELECT
			TO_CHAR(CURRENT_DATE, 'YYYY-MM-DD') AS date,
			COALESCE(SUM(amount_ml), 0) as total_ml
		FROM water_logs
		WHERE user_id = $1 AND created_at::date = CURRENT_DATE
	`, userID)

	stats.GoalML = goal
	return stats, err
}

func (s *nutritionService) GetWeeklyWaterStats(userID string) ([]DailyWaterStats, error) {
	var stats []DailyWaterStats
	err := db.DB.Select(&stats, `
		SELECT
			TO_CHAR(created_at::date, 'YYYY-MM-DD') as date,
			COALESCE(SUM(amount_ml), 0) as total_ml,
			2000 as goal_ml
		FROM water_logs
		WHERE user_id = $1 AND created_at >= NOW() - INTERVAL '6 days'
		GROUP BY created_at::date
		ORDER BY created_at::date
	`, userID)
	return stats, err
}

func (s *nutritionService) SetWaterGoal(userID string, goalML int) error {
	_, err := db.DB.Exec(`
		INSERT INTO water_goals (user_id, goal_ml)
		VALUES ($1, $2)
		ON CONFLICT (user_id)
		DO UPDATE SET goal_ml = EXCLUDED.goal_ml, updated_at = now()
	`, userID, goalML)
	return err
}

func (s *nutritionService) GetWaterGoal(userID string) (int, error) {
	var goal int
	err := db.DB.Get(&goal, `
		SELECT goal_ml FROM water_goals WHERE user_id = $1
	`, userID)

	if err != nil {
		return 2000, nil
	}

	return goal, nil
}

func (s *nutritionService) SetCalorieGoal(userID string, goal int) error {
	_, err := db.DB.Exec(`
		INSERT INTO calorie_goals (user_id, goal)
		VALUES ($1, $2)
		ON CONFLICT (user_id)
		DO UPDATE SET goal = EXCLUDED.goal, updated_at = now()
	`, userID, goal)
	return err
}

func (s *nutritionService) GetCalorieGoal(userID string) (int, error) {
	var goal int
	err := db.DB.Get(&goal, `
		SELECT goal FROM calorie_goals WHERE user_id = $1
	`, userID)
	if err != nil {
		return 2000, nil
	}
	return goal, nil
}

package models

import "time"

type Meal struct {
	ID          string    `db:"id" json:"id"`
	UserID      string    `db:"user_id" json:"-"`
	Description string    `db:"description" json:"description"`
	FdcID       int       `db:"fdc_id" json:"fdcId"`
	Calories    float64   `db:"calories" json:"calories"`
	Protein     float64   `db:"protein" json:"protein"`
	Fat         float64   `db:"fat" json:"fat"`
	Carbs       float64   `db:"carbs" json:"carbs"`
	Quantity    float64   `db:"quantity" json:"quantity"`
	Unit        string    `db:"unit" json:"unit"`
	EatenAt     time.Time `db:"eaten_at" json:"eatenAt"`
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

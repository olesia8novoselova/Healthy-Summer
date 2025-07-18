package services

import (
	"time"

	"github.com/timur-harin/sum25-go-flutter-course/backend/pkg/db"
)

type stepService struct {
}

// User is the exported singleton service.
var Step = &stepService{}

type StepStats struct {
	Today        int     `json:"today"`
	Goal         int     `json:"goal"`
	Progress     float64 `json:"progress"`
	WeeklyTotal  int     `json:"weekly_total"`
	MonthlyTotal int     `json:"monthly_total"`
}

type StepDay struct {
	Day   string `db:"day" json:"day"`
	Steps int    `db:"steps" json:"steps"`
}

func (s *stepService) AddOrUpdateSteps(userID string, steps int) error {
	today := time.Now().UTC().Format("2006-01-02")
	result, err := db.DB.Exec(`
        UPDATE user_steps SET steps = $1 WHERE user_id = $2 AND day = $3
    `, steps, userID, today)
	if err != nil {
		return err
	}
	rows, _ := result.RowsAffected()
	if rows == 0 {
		_, err = db.DB.Exec(`
            INSERT INTO user_steps (user_id, steps, day)
            VALUES ($1, $2, $3)
            ON CONFLICT (user_id, day) DO UPDATE SET steps = $2
        `, userID, steps, today)
	}
	return err
}

func (s *stepService) GetStepStats(userID string, goal int) (StepStats, error) {
	var stats StepStats
	today := time.Now().UTC().Format("2006-01-02")
	weekStart := time.Now().UTC().AddDate(0, 0, -int(time.Now().UTC().Weekday())).Format("2006-01-02")
	monthStart := time.Now().UTC().Format("2006-01-02")[:8] + "01"

	// Today
	_ = db.DB.Get(&stats.Today, `SELECT steps FROM user_steps WHERE user_id = $1 AND day = $2`, userID, today)
	// Weekly total
	_ = db.DB.Get(&stats.WeeklyTotal, `SELECT COALESCE(SUM(steps),0) FROM user_steps WHERE user_id = $1 AND day >= $2`, userID, weekStart)
	// Monthly total
	_ = db.DB.Get(&stats.MonthlyTotal, `SELECT COALESCE(SUM(steps),0) FROM user_steps WHERE user_id = $1 AND day >= $2`, userID, monthStart)

	stats.Goal = goal
	if goal > 0 {
		stats.Progress = float64(stats.Today) / float64(goal)
	} else {
		stats.Progress = 0
	}
	return stats, nil
}

func (s *stepService) GetStepAnalytics(userID string, days int) ([]StepDay, error) {
	var result []StepDay
	fromDay := time.Now().UTC().AddDate(0, 0, -days+1).Format("2006-01-02")
	err := db.DB.Select(&result, `
        SELECT day, steps FROM user_steps 
        WHERE user_id = $1 AND day >= $2 
        ORDER BY day DESC
    `, userID, fromDay)
	return result, err
}

func (s *stepService) AwardStepAchievements(userID string) error {
	var totalSteps int
	err := db.DB.Get(&totalSteps, `SELECT COALESCE(SUM(steps),0) FROM user_steps WHERE user_id = $1`, userID)
	if err != nil {
		return err
	}

	milestones := map[int]string{
		10000: "10,000 Steps",
		20000: "20,000 Steps",
		50000: "50,000 Steps",
	}

	for steps, title := range milestones {
		if totalSteps >= steps {
			err := User.AwardAchievementToUserID(userID, title)
			if err != nil {
				continue
			}
		}
	}
	return nil
}

func (s *stepService) SetStepGoal(userID string, goal int) error {
	_, err := db.DB.Exec(`
		INSERT INTO step_goals (user_id, goal)
		VALUES ($1, $2)
		ON CONFLICT (user_id) DO UPDATE SET goal = EXCLUDED.goal, updated_at = now()
	`, userID, goal)
	return err
}

func (s *stepService) GetStepGoal(userID string) (int, error) {
	var goal int
	err := db.DB.Get(&goal, `SELECT goal FROM step_goals WHERE user_id = $1`, userID)
	if err != nil {
		return 10000, nil
	}
	return goal, nil
}

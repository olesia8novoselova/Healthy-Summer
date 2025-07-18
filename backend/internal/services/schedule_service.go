package services

import (
	"log"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jmoiron/sqlx"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/models"
	"github.com/timur-harin/sum25-go-flutter-course/backend/pkg/db"
)

/* -------------------------------------------------------------------------- */
/*                                STRUCTURE                                   */
/* -------------------------------------------------------------------------- */

type scheduleService struct {
	db *sqlx.DB // will be filled lazily
}

// exported singleton (⚠️ do NOT grab db.DB here!)
var Schedule = &scheduleService{}

/* -------------------------------------------------------------------------- */
/*                          INTERNAL DB HELPER                                */
/* -------------------------------------------------------------------------- */

// always returns a *live* connection; nil while DB isn’t ready.
func (s *scheduleService) conn() *sqlx.DB {
	if s.db == nil {
		s.db = db.DB
	}
	return s.db
}

/* -------------------------------------------------------------------------- */
/*                                 CRUD                                       */
/* -------------------------------------------------------------------------- */

func (s *scheduleService) AddWorkout(id, uid string, wk int, at, title string) error {
	_, err := s.conn().Exec(`
		INSERT INTO workout_schedules (id,user_id,weekday,at_time,title)
		VALUES ($1,$2,$3,$4,$5)`, id, uid, wk, at, title)
	return err
}

func (s *scheduleService) ListWorkouts(uid string) ([]models.WorkoutSchedule, error) {
	var list []models.WorkoutSchedule
	err := s.conn().Select(&list,
		`SELECT * FROM workout_schedules WHERE user_id=$1`, uid)
	return list, err
}

func (s *scheduleService) DeleteWorkout(uid, id string) error {
	_, err := s.conn().Exec(
		`DELETE FROM workout_schedules WHERE id=$1 AND user_id=$2`, id, uid)
	return err
}

/* -------------------------------------------------------------------------- */
/*                              TICKER LOOP                                   */
/* -------------------------------------------------------------------------- */

func (s *scheduleService) StartTicker() {
	// ⬇️ fire every minute while developing
	interval := time.Minute
	// if needed, gate behind an env var:
	// if os.Getenv("ENV") == "prod" { interval = 30 * time.Minute }

	ticker := time.NewTicker(interval)

	go func() {
		for now := range ticker.C {
			if err := s.fireWorkout(now); err != nil {
				log.Printf("[Schedule] fireWorkout: %v", err)
			}
			s.fireHydration(now)
			s.fireChallengeDeadline(now)
		}
	}()
}

// ---------------- fireWorkout ----------------
// ---------------- fireWorkout ----------------
func (s *scheduleService) fireWorkout(now time.Time) error {
	// always grab a *live* handle – the first minute after boot
	// `db.DB` can still be nil while migrations run
	dbx := s.conn()
	if dbx == nil {
		return nil
	}

	// Monday = 0 … Sunday = 6 (client sends the same index)
	weekday := int(now.Weekday()+6) % 7
	cur := now.Format("15:04") // e.g. "18:30"

	var rows []struct {
		UserID string `db:"user_id"`
		Title  string `db:"title"`
	}

	// match ANY schedule within this exact minute
	if err := dbx.Select(&rows, `
		SELECT user_id, title
		FROM   workout_schedules
		WHERE  weekday               = $1
		  AND  to_char(at_time,'HH24:MI') = $2`,
		weekday, cur,
	); err != nil {
		return err
	}

	if len(rows) > 0 {
		log.Printf("[Schedule] %s – fired workout reminders for %d user(s)",
			cur, len(rows))
	}

	for _, r := range rows {
		ActivityHub.Broadcast(ActivityMessage{
			RecipientIDs: []string{r.UserID},
			Data: gin.H{
				"kind":  "reminder",
				"type":  "workout",
				"title": r.Title,
			},
		})
	}
	return nil
}

func (s *scheduleService) fireHydration(now time.Time) {
	dbx := s.conn()
	if dbx == nil {
		return
	}

	curMin := now.Hour()*60 + now.Minute()

	var rows []struct {
		UserID   string `db:"user_id"`
		Interval int    `db:"interval"`
	}
	_ = dbx.Select(&rows, `SELECT user_id,interval FROM hydration_settings`)

	for _, r := range rows {
		if r.Interval > 0 && curMin%r.Interval == 0 {
			ActivityHub.Broadcast(ActivityMessage{
				RecipientIDs: []string{r.UserID},
				Data: gin.H{
					"kind": "reminder",
					"type": "hydration",
				},
			})
		}
	}
}

func (s *scheduleService) fireChallengeDeadline(now time.Time) error {
	if now.Hour() != 23 || now.Minute() != 0 {
		return nil // run once a day at 23:00
	}
	dbx := s.conn()
	if dbx == nil {
		return nil
	}

	var rows []struct {
		UserID string `db:"user_id"`
		Title  string `db:"title"`
		ID     string `db:"id"`
		Target int    `db:"target"`
		Prog   int    `db:"progress"`
	}
	if err := dbx.Select(&rows, `
		SELECT cp.user_id,c.title,c.id,c.target,cp.progress
		FROM   challenge_participants cp
		JOIN   challenges            c ON c.id = cp.challenge_id
		WHERE  cp.progress < c.target
	`); err != nil {
		return err
	}

	for _, r := range rows {
		ActivityHub.Broadcast(ActivityMessage{
			RecipientIDs: []string{r.UserID},
			Data: gin.H{
				"kind":        "reminder",
				"type":        "challenge",
				"title":       r.Title,
				"challengeId": r.ID,
				"remaining":   r.Target - r.Prog,
			},
		})
	}
	return nil
}

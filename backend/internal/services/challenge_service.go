package services

import (
	"log"
	"time"

	"github.com/google/uuid"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/models"
	"github.com/timur-harin/sum25-go-flutter-course/backend/pkg/db"
)

type ChallengeService interface {
	Create(creatorID, title, ctype string, target int, friends []string) (models.Challenge, error)
	Join(chID, userID string) error
	UpdateProgress(userID, activityType string, delta int)
	Leaderboard(chID string) ([]models.ChallengeParticipant, error)
	ListForUser(userID string) ([]models.Challenge, error)
	BumpProgress(userID, ctype string, delta int) error
}

type challengeService struct{}

var Challenge ChallengeService = &challengeService{}

func (s *challengeService) Create(
	creatorID, title, ctype string, target int, friends []string,
) (models.Challenge, error) {

	ch := models.Challenge{
		ID: uuid.NewString(), CreatorID: creatorID,
		Title: title, Type: ctype, Target: target,
		CreatedAt: time.Now(),
	}

	tx, _ := db.DB.Beginx()
	if _, err := tx.NamedExec(`
        INSERT INTO challenges (id, creator_id, type, target, title, created_at)
        VALUES (:id,:creator_id,:type,:target,:title,:created_at)`, &ch); err != nil {
		tx.Rollback()
		return ch, err
	}

	seen := map[string]bool{creatorID: true}
	ids := []string{creatorID}

	for _, ident := range friends {
		var uid = ident
		if !isUUID(ident) {
			var err error
			uid, err = User.IDByEmail(ident)
			if err != nil || uid == "" {
				log.Printf("[Challenge] invite skipped, user not found: %v", ident)
				continue
			}
		}
		if !seen[uid] {
			ids = append(ids, uid)
			seen[uid] = true
		}
	}

	for _, uid := range ids {
		if _, err := tx.Exec(`
            INSERT INTO challenge_participants (challenge_id,user_id,progress,joined_at)
            VALUES ($1,$2,0,$3)`, ch.ID, uid, time.Now()); err != nil {
			tx.Rollback()
			return ch, err
		}
	}

	return ch, tx.Commit()
}

func (s *challengeService) Join(chID, userID string) error {
	_, err := db.DB.Exec(`INSERT INTO challenge_participants (challenge_id,user_id) VALUES ($1,$2) ON CONFLICT DO NOTHING`, chID, userID)
	return err
}

func (s *challengeService) UpdateProgress(userID, activityType string, delta int) {
	query := `UPDATE challenge_participants cp
            SET progress = progress + $1
            FROM challenges c
            WHERE cp.challenge_id = c.id AND cp.user_id = $2 AND c.type = $3`
	_, _ = db.DB.Exec(query, delta, userID, activityType)
}

func (s *challengeService) Leaderboard(chID string) ([]models.ChallengeParticipant, error) {
	var list []models.ChallengeParticipant
	err := db.DB.Select(&list, `SELECT * FROM challenge_participants WHERE challenge_id=$1 ORDER BY progress DESC`, chID)
	return list, err
}

func (s *challengeService) ListForUser(userID string) ([]models.Challenge, error) {
	var list []models.Challenge
	err := db.DB.Select(&list, `
        SELECT DISTINCT c.*
        FROM challenges c
        LEFT JOIN challenge_participants p
               ON p.challenge_id = c.id
        WHERE c.creator_id = $1 OR p.user_id = $1
        ORDER BY c.created_at DESC
    `, userID)
	return list, err
}

func isUUID(s string) bool { return len(s) == 36 && s[8] == '-' && s[13] == '-' }

func (s *challengeService) BumpProgress(userID, ctype string, delta int) error {
	res, err := db.DB.Exec(`
        UPDATE challenge_participants cp
        SET    progress = LEAST(cp.progress + $3, c.target)
        FROM   challenges c
        WHERE  cp.challenge_id = c.id
          AND  cp.user_id      = $1
          AND  c.type          = $2
    `, userID, ctype, delta)
	if err != nil {
		return err
	}

	rows, _ := res.RowsAffected()
	if rows == 0 {
		return nil
	}

	// ── award achievement for every challenge the user just completed ──
	// (progress == target)
	var completedIDs []string
	if err := db.DB.Select(&completedIDs, `
        SELECT cp.challenge_id
        FROM   challenge_participants cp
        JOIN   challenges c ON c.id = cp.challenge_id
        WHERE  cp.user_id = $1 AND cp.progress >= c.target
          AND  NOT EXISTS (
              SELECT 1 FROM user_achievements ua
              WHERE ua.user_id = $1
                AND ua.challenge_id = cp.challenge_id
          )
    `, userID); err != nil {
		return err
	}

	if len(completedIDs) == 0 {
		return nil
	}

	achID, err := Achieve.challengeAchievementID()
	if err != nil {
		return err
	}

	// insert one row per completed challenge
	for _, chID := range completedIDs {
		_, _ = db.DB.Exec(`
  INSERT INTO user_achievements (user_id, achievement_id, challenge_id)
  VALUES ($1, $2, $3) ON CONFLICT DO NOTHING
`, userID, achID, chID)

	}
	return nil
}

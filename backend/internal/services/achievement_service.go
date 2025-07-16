package services

import "github.com/timur-harin/sum25-go-flutter-course/backend/pkg/db"

type achievementService struct{}

var Achieve = &achievementService{}

func (s *achievementService) award(id, userID string) error {
    // id = achievements.id (UUID)
    _, err := db.DB.Exec(`
        INSERT INTO user_achievements (achievement_id, user_id)
        VALUES ($1, $2) ON CONFLICT DO NOTHING
    `, id, userID)
    return err
}

// helper that returns the canonical “Completed a Challenge” UUID
func (s *achievementService) challengeAchievementID() (string, error) {
    var id string
    err := db.DB.Get(&id, `SELECT id FROM achievements WHERE title = 'Completed a Challenge' LIMIT 1`)
    return id, err
}

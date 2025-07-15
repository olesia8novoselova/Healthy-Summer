package services

import (
	"log"
	"slices"
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/models"
	"github.com/timur-harin/sum25-go-flutter-course/backend/pkg/db"
)

type postService struct{

}

var Post = &postService{}

func (s *postService) CreateActivity(userID, actType, message string) (models.PostActivity, error) {
    activity := models.PostActivity{
        ID:        uuid.NewString(),
        UserID:    userID,
        Type:      actType,
        Message:   message,
        CreatedAt: time.Now(),
    }
    _, err := db.DB.Exec(`
        INSERT INTO post_activities (id, user_id, type, message, created_at)
        VALUES ($1, $2, $3, $4, $5)
    `, activity.ID, activity.UserID, activity.Type, activity.Message, activity.CreatedAt)
    return activity, err
}

func (s *postService) GetFriendsActivities(userID string, friendIDs []string, limit int) ([]models.PostActivity, error) {
    var activities []models.PostActivity

       if !slices.Contains(friendIDs, userID) {
        friendIDs = append(friendIDs, userID)
    }

    query := `
      SELECT a.id, a.user_id, a.type, a.message, a.created_at, u.name as user_name
      FROM post_activities a
      JOIN users u ON u.id = a.user_id
      WHERE a.user_id = ANY($1)
      ORDER BY a.created_at DESC
      LIMIT $2
    `

    log.Printf("Friend IDs + self: %+v", friendIDs)

    // if len(friendIDs) == 0 {
    //     return []models.PostActivity{}, nil
    // }

    err := db.DB.Select(&activities, query, pq.Array(friendIDs), limit)
    return activities, err
}


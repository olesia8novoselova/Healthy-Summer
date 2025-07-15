package services

import "github.com/timur-harin/sum25-go-flutter-course/backend/internal/models"

func NotifyFriendsOfActivity(userID string, activity models.PostActivity) {
	friendIDs, err := User.GetFriendIDs(userID)
	if err != nil {
		return
	}
	ActivityHub.Broadcast(ActivityMessage{
		RecipientIDs: friendIDs,
		Data:         activity,
	})
}

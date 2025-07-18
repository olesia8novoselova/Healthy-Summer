package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/joho/godotenv"

	"github.com/gin-gonic/gin"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/config"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/handlers"
	activity "github.com/timur-harin/sum25-go-flutter-course/backend/internal/handlers/activity"
	nutrition "github.com/timur-harin/sum25-go-flutter-course/backend/internal/handlers/nutrition"
	user "github.com/timur-harin/sum25-go-flutter-course/backend/internal/handlers/user"
	wellness "github.com/timur-harin/sum25-go-flutter-course/backend/internal/handlers/wellness"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/middleware"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/services"

	"github.com/timur-harin/sum25-go-flutter-course/backend/pkg/db"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, relying on real environment")
	}
	// Load configuration
	cfg := config.Load()
	if err := db.Init(cfg); err != nil {
		log.Fatalf("DB init failed: %v", err)
	}

	// Initialize Gin router
	if cfg.Env == "production" {
		gin.SetMode(gin.ReleaseMode)
	}
	services.Schedule.StartTicker()

	router := gin.New()

	// Add middleware
	router.Use(gin.Logger())
	router.Use(gin.Recovery())
	router.Use(middleware.CORS())

	// Health check endpoint
	router.GET("/health", handlers.HealthCheck)

	// API routes
	api := router.Group("/api")
	{
		api.GET("/ping", handlers.Ping)

		users := api.Group("/users")
		{
			users.POST("/register", user.Register)
			users.POST("/login", user.Login)

			// protected routes
			users.Use(middleware.Auth())
			users.GET("/profile", user.GetProfile)
			users.PUT("/profile", user.UpdateProfile)
			users.POST("/friends/request", user.RequestFriend)
			users.GET("/friends/requests", user.ListFriendRequests)
			users.GET("/friends", user.ListFriends)
			users.GET("/achievements", user.ListAllAchievements)
			users.GET("users/achievements", user.ListUserAchievements)
			users.POST("/friends/requests/:id/accept", user.AcceptFriendRequest)
			users.POST("/friends/requests/:id/decline", user.DeclineFriendRequest)

		}

		activities := api.Group("/activities")
		{
			activities.Use(middleware.Auth())
			activities.POST("", activity.AddActivity)
			activities.GET("", activity.ListActivities)
			activities.POST("/steps", activity.AddSteps)
			activities.GET("/stats", activity.GetStepStats)
			activities.GET("/analytics", activity.GetStepAnalytics)
			activities.POST("/steps/goal", activity.SetStepGoal)
			activities.GET("/steps/goal", activity.GetStepGoal)
			activities.POST("/goal", activity.SetActivityGoal)
			activities.GET("/goal", activity.GetActivityGoal)
			activities.GET("/today-calories", activity.GetTodayActivityCalories)
			activities.GET("/activity/weekly", activity.GetWeeklyActivityStats)
			activities.POST("/schedule/workouts", wellness.AddWorkout)
			activities.GET("/schedule/workouts", wellness.ListWorkouts)
			activities.DELETE("/schedule/workouts/:id", wellness.DeleteWorkout)
		}

		nutritionGroup := api.Group("/nutrition")
		{
			nutritionGroup.Use(middleware.Auth())
			nutritionGroup.GET("/foods/search", handlers.SearchUSDAFoods)
			nutritionGroup.POST("/meals", nutrition.AddMeal)
			nutritionGroup.GET("/meals", nutrition.ListMeals)
			nutritionGroup.GET("/stats", nutrition.GetNutritionStats)
			nutritionGroup.GET("/stats/weekly", nutrition.GetWeeklyNutritionStats)
			nutritionGroup.POST("/water", nutrition.AddWaterLog)
			nutritionGroup.GET("/water/today", nutrition.GetTodayWaterStats)
			nutritionGroup.GET("/water/weekly", nutrition.GetWeeklyWaterStats)
			nutritionGroup.POST("/water/goal", nutrition.SetWaterGoal)
			nutritionGroup.GET("/water/goal", nutrition.GetWaterGoal)
			nutritionGroup.POST("/calories/goal", nutrition.SetCalorieGoal)
			nutritionGroup.GET("/calories/goal", nutrition.GetCalorieGoal)
		}

		wellnessGroup := api.Group("/wellness")
		{
			wellnessGroup.GET("/ws", wellness.WebSocketHandler)

			wellnessGroup.Use(middleware.Auth())
			wellnessGroup.POST("/activities", wellness.PostActivity)
			wellnessGroup.GET("/activities", wellness.GetFriendsActivities)
			wellnessGroup.GET("/ws/activity", wellness.ActivitySocket)
			wellnessGroup.GET("/messages/:friendId", wellness.GetMessages)
			wellnessGroup.GET("/friends", wellness.GetChatList)
			wellnessGroup.POST("/messages", wellness.PostMessage)
			wellnessGroup.POST("/challenges", wellness.CreateChallenge)
			wellnessGroup.GET("/challenges", wellness.ListChallenges)
			wellnessGroup.POST("/challenges/:id/join", wellness.JoinChallenge)
			wellnessGroup.GET("/challenges/:id/leaderboard", wellness.GetLeaderboard)
		}
	}

	// Create HTTP server
	server := &http.Server{
		Addr:    ":" + cfg.Port,
		Handler: router,
	}

	// Start server in a goroutine
	go func() {
		log.Printf("🚀 Server starting on port %s", cfg.Port)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("🛑 Shutting down server...")

	// Give outstanding requests 10 seconds to complete
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("✅ Server exited")
}

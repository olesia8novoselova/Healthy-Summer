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
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/middleware"
	user "github.com/timur-harin/sum25-go-flutter-course/backend/internal/handlers/user"
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
	//log.Println("Loaded JWT_SECRET:", cfg.JWTSecret)


	// Initialize Gin router
	if cfg.Env == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()

	// Add middleware
	router.Use(gin.Logger())
	router.Use(gin.Recovery())
	router.Use(middleware.CORS())

	// Health check endpoint
	router.GET("/health", handlers.HealthCheck)

	// API routes
	api := router.Group("/api/v1")
	{
		api.GET("/ping", handlers.Ping)
		// Add more routes as needed
		users := api.Group("/users")
		{
			users.POST("/register", user.Register)
			users.POST("/login", user.Login)

			// protected routes
			
		    users.Use(middleware.Auth())
		    
			
			{
				users.GET("/profile", user.GetProfile)
				users.PUT("/profile", user.UpdateProfile)
				users.POST("/friends/request", user.RequestFriend)
				users.GET("/friends", user.ListFriends)
				users.POST("/achievements", user.AwardAchievement)
				users.GET("/achievements", user.ListAllAchievements)
				users.GET("users/achievements", user.ListUserAchievements)
			}
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

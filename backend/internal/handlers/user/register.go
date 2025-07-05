package user

import (
    "log"
    "net/http"

    "github.com/gin-gonic/gin"
    "github.com/timur-harin/sum25-go-flutter-course/backend/internal/services"
)

type registerRequest struct {
    Name     string `json:"name" binding:"required"`
    Email    string `json:"email" binding:"required,email"`
    Password string `json:"password" binding:"required"`
}

// Register handles user registration
func Register(c *gin.Context) {
    var req registerRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    if err := services.User.CreateUser(req.Name, req.Email, req.Password); err != nil {
        log.Printf("CreateUser error: %v", err)
        // Return detailed error for client debugging
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, gin.H{"message": "registered"})
}

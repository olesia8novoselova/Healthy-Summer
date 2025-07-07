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

// Register handles user registration and returns a JWT
func Register(c *gin.Context) {
    var req registerRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    // Create the user
    if err := services.User.CreateUser(req.Name, req.Email, req.Password); err != nil {
        log.Printf("CreateUser error: %v", err)
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    // Authenticate to generate JWT
    token, err := services.User.Authenticate(req.Email, req.Password)
    if err != nil {
        log.Printf("Authenticate after register error: %v", err)
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate token"})
        return
    }
    log.Printf("JWT after registration for %s: %s", req.Email, token)


    // Return token in response
    c.JSON(http.StatusOK, gin.H{"token": token})
}

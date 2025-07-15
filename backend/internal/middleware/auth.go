package middleware

import (
	"log"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/timur-harin/sum25-go-flutter-course/backend/pkg/auth"
)

func Auth() gin.HandlerFunc {
    return func(c *gin.Context) {
        // 1. Grab the header
        header := c.GetHeader("Authorization")
        if header == "" {
            c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Authorization header required"})
            return
        }
        //log.Println("Authorization header received:", header)
        


        // 2. Expect “Bearer <token>”
        parts := strings.SplitN(header, " ", 2)
        if len(parts) != 2 || parts[0] != "Bearer" {
            c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Authorization header format must be Bearer {token}"})
            return
        }
        tokenStr := parts[1]

        // 3. Parse & validate token
        claims, err := auth.ParseToken(tokenStr)
        if err != nil {
            c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
            return
        }

        log.Println("Token part extracted:", tokenStr)

        // 4. Inject userID into context for handlers
        c.Set("userID", claims.UserID)

        c.Next()
    }
}

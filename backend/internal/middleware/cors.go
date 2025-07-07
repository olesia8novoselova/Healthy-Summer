package middleware

import "github.com/gin-gonic/gin"

// CORS handles Cross-Origin Resource Sharing, including auth headers.
func CORS() gin.HandlerFunc {
    return func(c *gin.Context) {
        origin := c.GetHeader("Origin")
        if origin != "" {
            // Echo back the requesting origin instead of "*"
            c.Writer.Header().Set("Access-Control-Allow-Origin", origin)
            c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
        } else {
            // Fallback if no Origin header
            c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
        }

        c.Writer.Header().Set(
            "Access-Control-Allow-Headers",
            "Content-Type, Authorization, X-CSRF-Token, X-Requested-With, Accept, Origin, Cache-Control, Content-Length",
        )
        c.Writer.Header().Set(
            "Access-Control-Allow-Methods",
            "GET, POST, PUT, PATCH, DELETE, OPTIONS",
        )

        if c.Request.Method == "OPTIONS" {
            c.AbortWithStatus(204)
            return
        }
        c.Next()
    }
}

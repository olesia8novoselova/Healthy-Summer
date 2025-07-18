package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// CORS handles Cross-Origin Resource Sharing, including credentials.
func CORS() gin.HandlerFunc {
	return func(c *gin.Context) {
		origin := c.GetHeader("Origin")

		if origin != "" {
			c.Writer.Header().Set("Access-Control-Allow-Origin", origin)
			c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
			c.Writer.Header().Set("Vary", "Origin") // cache correctness
		} else {
			// No Origin header → treat as same-origin call, or tighten policy.
			// You could simply fall through without CORS headers.
			c.AbortWithStatus(403)
			return
		}

		c.Writer.Header().Set("Access-Control-Allow-Headers",
			"Authorization, Content-Type, X-CSRF-Token, X-Requested-With, Accept, Origin, Cache-Control, Content-Length",
		)
		c.Writer.Header().Set("Access-Control-Allow-Methods",
			"GET, POST, PUT, PATCH, DELETE, OPTIONS",
		)
		c.Writer.Header().Set("Access-Control-Max-Age", "3600")
		c.Writer.Header().Set("Access-Control-Expose-Headers",
			"Content-Length, Content-Disposition, X-Total-Count",
		)

		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(204) // pre-flight OK
			return
		}

		c.Next()
	}
}

package auth

import "github.com/golang-jwt/jwt/v4"
import "github.com/timur-harin/sum25-go-flutter-course/backend/internal/config"

type Claims struct {
    UserID string `json:"userId"`
    jwt.RegisteredClaims
}

func GenerateToken(claims Claims) (string, error) {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte("secretkey"))
}

// ParseToken verifies the JWT and returns the custom claims
func ParseToken(tokenStr string) (*Claims, error) {
	cfg := config.Load()

    token, err := jwt.ParseWithClaims(tokenStr, &Claims{}, func(t *jwt.Token) (interface{}, error) {
        return []byte(cfg.JWTSecret), nil
    })
    if err != nil {
        return nil, err
    }
    if claims, ok := token.Claims.(*Claims); ok && token.Valid {
        return claims, nil
    }
    return nil, err
}

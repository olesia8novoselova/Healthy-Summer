package db

import (
    "fmt"

    "github.com/jmoiron/sqlx"
    _ "github.com/lib/pq"

    "github.com/timur-harin/sum25-go-flutter-course/backend/internal/config"
)

// DB is the global database handle.
var DB *sqlx.DB

// Init initializes the global DB connection using the provided config.
func Init(cfg *config.Config) error {
    // Ensure your config.Config has a DatabaseURL field, e.g.: env var DATABASE_URL="postgres://user:pass@host:port/dbname?sslmode=disable"
    dsn := cfg.DatabaseURL
    
    db, err := sqlx.Connect("postgres", dsn)
    if err != nil {
        return fmt.Errorf("failed to connect to DB: %w", err)
    }
    
    DB = db
    return nil
}

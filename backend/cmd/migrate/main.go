package main

import (
	"errors"
	"flag"
	"fmt"
	"log/slog"

	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"

	"github.com/arseniizyk/food-analyser/backend/internal/config"
)

func main() {
	path := flag.String("path", "", "path to env file")
	flag.Parse()

	cfg, err := config.New(*path)
	if err != nil {
		panic(fmt.Errorf("failed to build config: %w", err))
	}

	connString := fmt.Sprintf("postgres://%s:%s@%s:%d/%s?sslmode=%s",
		cfg.Postgres.User,
		cfg.Postgres.Password,
		cfg.Postgres.Host,
		cfg.Postgres.Port,
		cfg.Postgres.DBName,
		cfg.Postgres.SSLMode,
	)

	m, err := migrate.New(
		"file://migrations",
		connString,
	)
	if err != nil {
		panic(fmt.Errorf("failed to create migration: %w", err))
	}

	if err := m.Up(); err != nil && !errors.Is(err, migrate.ErrNoChange) {
		panic(fmt.Errorf("failed to apply migrations: %w", err))
	}

	slog.Info("Migrations applied successfully!")
}

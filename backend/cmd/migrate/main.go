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

	m, err := migrate.New(
		"file://migrations",
		cfg.Postgres.ConnString(),
	)
	if err != nil {
		panic(fmt.Errorf("failed to create migration: %w", err))
	}

	if err := m.Up(); err != nil && !errors.Is(err, migrate.ErrNoChange) {
		panic(fmt.Errorf("failed to apply migrations: %w", err))
	}

	slog.Info("Migrations applied successfully!")
}

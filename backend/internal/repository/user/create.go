package user

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"

	"github.com/arseniizyk/food-analyser/backend/internal/models"
)

func (r *Repository) CreateIfNotExists(ctx context.Context, googleID string) (*models.User, error) {
	if u, err := r.GetByGoogleID(ctx, googleID); err == nil {
		return u, nil
	}

	id := uuid.New()
	now := time.Now().UTC()

	query, args, err := r.sb.Insert("users").Columns("id", "google_id", "created_at").Values(id, googleID, now).ToSql()
	if err != nil {
		return nil, fmt.Errorf("build insert: %w", err)
	}

	if _, err := r.pool.Exec(ctx, query, args...); err != nil {
		return nil, fmt.Errorf("exec insert: %w", err)
	}

	return &models.User{ID: id, GoogleID: googleID, CreatedAt: now}, nil
}

func (r *Repository) AddScan(ctx context.Context, userID, barcode string) error {
	query, args, err := r.sb.Insert("user_scans").Columns("user_id", "barcode", "created_at").Values(userID, barcode, time.Now().UTC()).ToSql()
	if err != nil {
		return fmt.Errorf("build insert scan: %w", err)
	}

	cmd, err := r.pool.Exec(ctx, query, args...)
	if err != nil {
		return fmt.Errorf("exec insert scan: %w", err)
	}
	if cmd.RowsAffected() == 0 {
		return fmt.Errorf("failed to add scan: %w", err)
	}

	return nil
}

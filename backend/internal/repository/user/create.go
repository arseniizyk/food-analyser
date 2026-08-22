package user

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/arseniizyk/food-analyser/backend/internal/models"
)

func (r *Repository) CreateIfNotExists(ctx context.Context, googleID string) (*models.User, error) {
	id := uuid.New()
	now := time.Now().UTC()

	query, args, err := r.sb.
		Insert("users").
		Columns("id", "google_id", "created_at").
		Values(id, googleID, now).
		Suffix("ON CONFLICT (google_id) DO NOTHING RETURNING id, google_id, created_at").
		ToSql()
	if err != nil {
		return nil, fmt.Errorf("build insert: %w", err)
	}

	var u models.User
	if err := r.pool.QueryRow(ctx, query, args...).Scan(&u.ID, &u.GoogleID, &u.CreatedAt); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return r.GetByGoogleID(ctx, googleID)
		}
		return nil, fmt.Errorf("exec insert: %w", err)
	}

	return &u, nil
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

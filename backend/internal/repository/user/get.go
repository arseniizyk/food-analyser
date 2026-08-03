package user

import (
	"context"
	"fmt"

	sq "github.com/Masterminds/squirrel"

	"github.com/arseniizyk/food-analyser/backend/internal/errs"
	"github.com/arseniizyk/food-analyser/backend/internal/models"
)

func (r *Repository) GetByGoogleID(ctx context.Context, googleID string) (*models.User, error) {
	query, args, err := r.sb.Select("id", "google_id", "created_at").From("users").Where(sq.Eq{"google_id": googleID}).ToSql()
	if err != nil {
		return nil, fmt.Errorf("build query: %w", err)
	}

	var u models.User
	row := r.pool.QueryRow(ctx, query, args...)
	if err := row.Scan(&u.ID, &u.GoogleID, &u.CreatedAt); err != nil {
		return nil, errs.ErrUserNotFound
	}
	return &u, nil
}

// TODO: check if scans is null
func (r *Repository) GetScans(ctx context.Context, userID string) ([]string, error) {
	query, args, err := r.sb.Select("barcode").From("user_scans").Where(sq.Eq{"user_id": userID}).OrderBy("created_at DESC").ToSql()
	if err != nil {
		return nil, fmt.Errorf("build query scans: %w", err)
	}

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("query scans: %w", err)
	}
	defer rows.Close()

	var res []string
	for rows.Next() {
		var barcode string
		if err := rows.Scan(&barcode); err != nil {
			return nil, fmt.Errorf("scan row: %w", err)
		}
		res = append(res, barcode)
	}
	return res, nil
}

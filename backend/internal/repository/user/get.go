package user

import (
	"context"
	"errors"
	"fmt"

	sq "github.com/Masterminds/squirrel"
	"github.com/jackc/pgx/v5"

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
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, errs.ErrUserNotFound
		}
		return nil, fmt.Errorf("scan user: %w", err)
	}
	return &u, nil
}

func (r *Repository) IsExists(ctx context.Context, userID string) error {
	var exists int

	query, args, err := r.sb.
		Select("1").
		From("users").
		Where(sq.Eq{"id": userID}).
		Limit(1).
		ToSql()
	if err != nil {
		return fmt.Errorf("build query: %w", err)
	}

	if err := r.pool.QueryRow(ctx, query, args...).Scan(&exists); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return errs.ErrUserNotFound
		}
		return fmt.Errorf("check user existence: %w", err)
	}

	return nil
}

func (r *Repository) GetScans(ctx context.Context, userID string) ([]models.Scan, error) {
	if err := r.IsExists(ctx, userID); err != nil {
		return nil, err
	}

	query, args, err := r.sb.Select("s.barcode", "s.created_at", "COALESCE(a.score, 0)").
		From("user_scans s").
		LeftJoin("analyses a ON a.barcode = s.barcode").
		Where(sq.Eq{"s.user_id": userID}).
		OrderBy("s.created_at DESC").
		ToSql()
	if err != nil {
		return nil, fmt.Errorf("build query scans: %w", err)
	}

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("query scans: %w", err)
	}
	defer rows.Close()

	res := make([]models.Scan, 0)
	for rows.Next() {
		var scan models.Scan
		if err := rows.Scan(&scan.Barcode, &scan.CreatedAt, &scan.Score); err != nil {
			return nil, fmt.Errorf("scan row: %w", err)
		}
		res = append(res, scan)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("rows iteration: %w", err)
	}

	return res, nil
}

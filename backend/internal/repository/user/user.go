package user

import (
	"context"
	"fmt"
	"time"

	sq "github.com/Masterminds/squirrel"
	"github.com/arseniizyk/food-analyser/backend/internal/models"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/arseniizyk/food-analyser/backend/internal/errs"
)

type Repository struct {
	pool *pgxpool.Pool
	sb   sq.StatementBuilderType
}

func New(pool *pgxpool.Pool) *Repository {
	return &Repository{pool: pool, sb: sq.StatementBuilder.PlaceholderFormat(sq.Dollar)}
}

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

func (r *Repository) CreateIfNotExists(ctx context.Context, googleID string) (*models.User, error) {
	// Try to get existing
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

func (r *Repository) AddScan(ctx context.Context, userID uuid.UUID, barcode string) error {
	query, args, err := r.sb.Insert("user_scans").Columns("user_id", "barcode", "created_at").Values(userID, barcode, time.Now().UTC()).ToSql()
	if err != nil {
		return fmt.Errorf("build insert scan: %w", err)
	}
	if _, err := r.pool.Exec(ctx, query, args...); err != nil {
		return fmt.Errorf("exec insert scan: %w", err)
	}
	return nil
}

func (r *Repository) GetScans(ctx context.Context, userID uuid.UUID) ([]string, error) {
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

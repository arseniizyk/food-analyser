package product

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"

	sq "github.com/Masterminds/squirrel"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/arseniizyk/food-analyser/backend/internal/models"
)

type Repository struct {
	pool *pgxpool.Pool
	sb   sq.StatementBuilderType
}

func New(pool *pgxpool.Pool) *Repository {
	return &Repository{
		pool: pool,
		sb:   sq.StatementBuilder.PlaceholderFormat(sq.Dollar),
	}
}

func (repo *Repository) GetAnalysisByBarcode(
	ctx context.Context,
	barcode string,
) (*models.Analysis, error) {
	query, args, err := repo.sb.
		Select("barcode", "grade", "score", "summary", "risks", "ingredients").
		From("analyses").
		Where(sq.Eq{"barcode": barcode}).
		ToSql()
	if err != nil {
		return nil, fmt.Errorf("build query: %w", err)
	}

	var (
		analysis       models.Analysis
		summaryRaw     json.RawMessage
		risksRaw       json.RawMessage
		ingredientsRaw json.RawMessage
	)

	err = repo.pool.QueryRow(ctx, query, args...).Scan(
		&analysis.Barcode,
		&analysis.Grade,
		&analysis.Score,
		&summaryRaw,
		&risksRaw,
		&ingredientsRaw,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("scan: %w", err)
	}

	if err := json.Unmarshal(summaryRaw, &analysis.Summary); err != nil {
		return nil, fmt.Errorf("scanning summary: %w", err)
	}
	if err := json.Unmarshal(risksRaw, &analysis.Risks); err != nil {
		return nil, fmt.Errorf("scanning risks: %w", err)
	}
	if err := json.Unmarshal(ingredientsRaw, &analysis.Ingredients); err != nil {
		return nil, fmt.Errorf("scanning ingredients: %w", err)
	}

	return &analysis, nil
}

func (repo *Repository) SaveAnalysis(ctx context.Context, analysis *models.Analysis) error {
	summaryRaw, err := json.Marshal(analysis.Summary)
	if err != nil {
		return fmt.Errorf("scanning summary: %w", err)
	}
	risksRaw, err := json.Marshal(analysis.Risks)
	if err != nil {
		return fmt.Errorf("scanning risks: %w", err)
	}
	ingredientsRaw, err := json.Marshal(analysis.Ingredients)
	if err != nil {
		return fmt.Errorf("scanning ingredients: %w", err)
	}

	query, args, err := repo.sb.
		Insert("analyses").
		Columns("barcode", "grade", "score", "summary", "risks", "ingredients").
		Values(analysis.Barcode, analysis.Grade, analysis.Score, summaryRaw, risksRaw, ingredientsRaw).
		Suffix(`
			ON CONFLICT (barcode)
			DO UPDATE SET
				grade = EXCLUDED.grade,
				score = EXCLUDED.score,
				summary = EXCLUDED.summary,
				risks = EXCLUDED.risks,
				ingredients = EXCLUDED.ingredients
		`).
		ToSql()
	if err != nil {
		return fmt.Errorf("build query: %w", err)
	}

	if _, err := repo.pool.Exec(ctx, query, args...); err != nil {
		return fmt.Errorf("exec query: %w", err)
	}

	return nil
}

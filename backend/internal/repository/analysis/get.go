package analysis

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"

	sq "github.com/Masterminds/squirrel"
	"github.com/jackc/pgx/v5"

	"github.com/arseniizyk/food-analyser/backend/internal/errs"
	"github.com/arseniizyk/food-analyser/backend/internal/models"
)

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
			return nil, errs.ErrAnalysisNotFound
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

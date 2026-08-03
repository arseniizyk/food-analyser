package analysis

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/arseniizyk/food-analyser/backend/internal/models"
)

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

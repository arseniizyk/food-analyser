package analysis

import (
	"context"
	"io"

	"github.com/arseniizyk/food-analyser/backend/internal/errs"
	"github.com/arseniizyk/food-analyser/backend/internal/models"
)

func (s *Service) Analyze(ctx context.Context, barcode string, image io.Reader) (*models.Analysis, error) {
	l := s.logger.With(
		"operation", "AnalyzeProduct",
		"barcode", barcode,
	)
	nutrition, err := s.mlService.GetTextFromPhoto(ctx, image)
	if err != nil {
		// Warn because user may send bad photo
		l.Warn("failed to recognize text from photo", "error", err)
		return nil, errs.ErrRecognizeFromImage
	}

	analysis, err := s.llmService.AnalyzeNutrition(ctx, nutrition)
	if err != nil {
		l.Error("failed to analyze nutrition",
			"nutrition_len", len(nutrition),
			"nutrition_preview", nutrition[:min(100, len(nutrition))],
			"error", err,
		)
		return nil, errs.ErrAnalysingNutrition
	}

	analysis.Barcode = barcode
	if err := s.repo.SaveAnalysis(ctx, analysis); err != nil {
		l.Error("failed to save analysis",
			"nutrition_len", len(nutrition),
			"nutrition_preview", nutrition[:min(100, len(nutrition))],
			"error", err,
		)
		// Ошибка сохранения не влияет на ответ пользователю.
		// Анализ уже получен, поэтому возвращаем его несмотря на проблему с БД.
	}

	return analysis, nil
}

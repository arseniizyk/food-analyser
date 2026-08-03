package analysis

import (
	"context"
	"errors"
	"fmt"

	"github.com/arseniizyk/food-analyser/backend/internal/errs"
	"github.com/arseniizyk/food-analyser/backend/internal/models"
)

func (s *Service) GetAnalysisByBarcode(ctx context.Context, barcode string) (*models.Analysis, error) {
	l := s.logger.With(
		"operation", "GetAnalysisByBarcode",
		"barcode", barcode,
	)
	analysis, err := s.repo.GetAnalysisByBarcode(ctx, barcode)
	if err != nil {
		if !errors.Is(err, errs.ErrAnalysisNotFound) {
			l.Error("failed to get analysis by barcode", "error", err)
		}
		return nil, fmt.Errorf("failed to get analysis from repo: %w", err)
	}

	return analysis, nil
}

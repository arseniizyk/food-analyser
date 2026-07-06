package product

import (
	"context"
	"fmt"
	"io"
	"log/slog"

	"github.com/arseniizyk/food-analyser/backend/internal/errs"
	"github.com/arseniizyk/food-analyser/backend/internal/models"
)

type Repository interface {
	GetAnalysisByBarcode(ctx context.Context, barcode string) (*models.Analysis, error)
	SaveAnalysis(ctx context.Context, analysis *models.Analysis) error
}

type MLService interface {
	GetTextFromPhoto(ctx context.Context, image io.Reader) (string, error)
}

type LLMService interface {
	AnalyzeNutrition(ctx context.Context, nutrition string) (*models.Analysis, error)
}

type Service struct {
	repo Repository

	// Сервис на Python для распознавания текста с фото
	mlService MLService
	// Стороннее API для анализа состава продукта по тексту
	llmService LLMService
}

func New(repo Repository, mlService MLService, llmService LLMService) *Service {
	return &Service{
		repo:       repo,
		llmService: llmService,
		mlService:  mlService,
	}
}

func (s *Service) GetAnalysisByBarcode(ctx context.Context, barcode string) (*models.Analysis, error) {
	analysis, err := s.repo.GetAnalysisByBarcode(ctx, barcode)
	if err != nil {
		return nil, fmt.Errorf("failed to get analysis from repo: %w", err)
	}

	return analysis, nil
}

func (s *Service) AnalyzeProduct(ctx context.Context, barcode string, image io.Reader) (*models.Analysis, error) {
	log := slog.With(
		"operation", "AnalyzeProduct",
		"barcode", barcode,
	)
	nutrition, err := s.mlService.GetTextFromPhoto(ctx, image)
	if err != nil {
		log.Warn("failed to recognize text from photo", "error", err)
		return nil, errs.ErrRecognizeFromImage
	}

	analysis, err := s.llmService.AnalyzeNutrition(ctx, nutrition)
	if err != nil {
		log.Error("failed to analyze nutrition",
			"nutrition_len", len(nutrition),
			"nutrition_preview", nutrition[:min(100, len(nutrition))],
			"error", err,
		)
		return nil, errs.ErrAnalysingNutrition
	}

	analysis.Barcode = barcode
	if err := s.repo.SaveAnalysis(ctx, analysis); err != nil {
		log.Error("failed to save analysis",
			"nutrition_len", len(nutrition),
			"nutrition_preview", nutrition[:min(100, len(nutrition))],
			"error", err,
		)
		// Ошибка сохранения не влияет на ответ пользователю.
		// Анализ уже получен, поэтому возвращаем его несмотря на проблему с БД.
	}

	return analysis, nil
}

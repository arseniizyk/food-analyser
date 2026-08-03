package analysis

import (
	"context"
	"io"
	"log/slog"

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
	repo   Repository
	logger *slog.Logger

	// Сервис на Python для распознавания текста с фото
	mlService MLService
	// Стороннее API для анализа состава продукта по тексту
	llmService LLMService
}

func New(logger *slog.Logger, repo Repository, mlService MLService, llmService LLMService) *Service {
	return &Service{
		repo:       repo,
		llmService: llmService,
		mlService:  mlService,
		logger:     logger,
	}
}

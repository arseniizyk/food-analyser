package llm

import (
	"context"

	"github.com/arseniizyk/food-analyser/backend/internal/config"
	"github.com/arseniizyk/food-analyser/backend/internal/models"
)

type Service struct{}

func New(cfg config.LLMConfig) *Service {
	return &Service{}
}

func (s *Service) AnalyzeNutrition(ctx context.Context, nutrition string) (*models.Analysis, error) {
	return nil, nil
}

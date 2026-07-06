package product

import (
	"context"

	"github.com/arseniizyk/food-analyser/backend/internal/models"
)

type Repository interface {
	GetAnalysisByBarcode(ctx context.Context, barcode string) (*models.Analysis, error)
	SaveAnalysis(ctx context.Context, analysis *models.Analysis) error
}

type Service struct {
	repo Repository
}

func New(repo Repository) *Service { return &Service{repo: repo} }

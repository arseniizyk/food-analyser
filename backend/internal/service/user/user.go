package user

import (
	"context"
	"log/slog"

	"github.com/arseniizyk/food-analyser/backend/internal/models"
)

type Repository interface {
	GetByGoogleID(ctx context.Context, googleID string) (*models.User, error)
	CreateIfNotExists(ctx context.Context, googleID string) (*models.User, error)
	AddScan(ctx context.Context, userID, barcode string) error
	GetScans(ctx context.Context, userID string) ([]string, error)
}

type Service struct {
	repository Repository
	logger     *slog.Logger
}

func New(logger *slog.Logger, repository Repository) *Service {
	return &Service{
		repository: repository,
		logger:     logger,
	}
}

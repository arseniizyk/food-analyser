package analysis

import (
	"context"
	"io"
	"log/slog"

	"github.com/arseniizyk/food-analyser/backend/internal/models"
)

type Service interface {
	GetAnalysisByBarcode(ctx context.Context, barcode string) (*models.Analysis, error)
	Analyze(ctx context.Context, barcode string, image io.Reader) (*models.Analysis, error)
}

type UserService interface {
	AddScan(ctx context.Context, userID, barcode string) error
}

type Handler struct {
	userService UserService
	service     Service
	logger      *slog.Logger
}

func New(logger *slog.Logger, service Service, userService UserService) *Handler {
	return &Handler{
		service:     service,
		userService: userService,
		logger:      logger,
	}
}

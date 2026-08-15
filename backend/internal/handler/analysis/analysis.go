package analysis

import (
	"context"
	"io"

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
}

func New(service Service, userService UserService) *Handler {
	return &Handler{
		service:     service,
		userService: userService,
	}
}

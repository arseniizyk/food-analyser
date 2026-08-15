package user

import (
	"context"
	"log/slog"

	"github.com/arseniizyk/food-analyser/backend/internal/models"
)

type UserService interface {
	GetScans(ctx context.Context, userID string) ([]models.Scan, error)
}

type Service interface {
	Authenticate(ctx context.Context, idToken string) (userID, accessToken, email string, err error)
}

type Handler struct {
	userService UserService
	authService Service
	logger      *slog.Logger
}

func New(logger *slog.Logger, authService Service, userService UserService) *Handler {
	return &Handler{
		authService: authService,
		userService: userService,
		logger:      logger,
	}
}

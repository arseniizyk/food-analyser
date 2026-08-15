package user

import (
	"context"

	"github.com/arseniizyk/food-analyser/backend/internal/models"
)

type UserService interface {
	GetScans(ctx context.Context, userID string) ([]models.Scan, error)
}

type Service interface {
	Authenticate(ctx context.Context, idToken string) (string, error)
}

type Handler struct {
	userService UserService
	authService Service
}

func New(authService Service, userService UserService) *Handler {
	return &Handler{
		authService: authService,
		userService: userService,
	}
}

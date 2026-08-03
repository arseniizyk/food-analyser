package auth

import (
	"context"
	"log/slog"
	"net/http"

	"github.com/arseniizyk/food-analyser/backend/internal/models"
)

type UserRepository interface {
	CreateIfNotExists(ctx context.Context, googleID string) (*models.User, error)
}

type Service struct {
	clientID       string
	userRepository UserRepository
	httpClient     *http.Client
	logger         *slog.Logger
}

func New(logger *slog.Logger, clientID string, users UserRepository) *Service {
	return &Service{
		clientID:       clientID,
		userRepository: users,
		logger:         logger,
		httpClient:     &http.Client{}, // TODO: add timeouts
	}
}

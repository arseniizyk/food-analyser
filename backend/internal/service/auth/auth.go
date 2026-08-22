package auth

import (
	"context"
	"log/slog"
	"net/http"
	"time"

	"github.com/arseniizyk/food-analyser/backend/internal/models"
	jwtpkg "github.com/arseniizyk/food-analyser/backend/internal/service/jwt"
)

type UserRepository interface {
	CreateIfNotExists(ctx context.Context, googleID string) (*models.User, error)
}

type Service struct {
	clientID       string
	iosClientID    string
	tokenInfoURL   string
	userRepository UserRepository
	jwtManager     *jwtpkg.Manager
	httpClient     *http.Client
	logger         *slog.Logger
}

func New(logger *slog.Logger, clientID, iosClientID string, users UserRepository, jwtManager *jwtpkg.Manager) *Service {
	return &Service{
		clientID:       clientID,
		iosClientID:    iosClientID,
		tokenInfoURL:   "https://oauth2.googleapis.com/tokeninfo",
		userRepository: users,
		jwtManager:     jwtManager,
		logger:         logger,
		httpClient:     &http.Client{Timeout: 10 * time.Second},
	}
}

package auth

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"

	"github.com/arseniizyk/food-analyser/backend/internal/models"
)

type UserRepository interface {
	CreateIfNotExists(ctx context.Context, googleID string) (*models.User, error)
}

type Service struct {
	clientID string
	users    UserRepository
}

func New(clientID string, users UserRepository) *Service {
	return &Service{clientID: clientID, users: users}
}

// tokenInfo represents a subset of fields returned by Google's tokeninfo endpoint.
type tokenInfo struct {
	Aud              string `json:"aud"`
	Sub              string `json:"sub"`
	ErrorDescription string `json:"error_description"`
}

func (s *Service) Authenticate(ctx context.Context, idToken string) (string, error) {
	if idToken == "" {
		return "", errors.New("empty id token")
	}

	// Verify ID token with Google's tokeninfo endpoint
	resp, err := http.Get("https://oauth2.googleapis.com/tokeninfo?id_token=" + idToken)
	if err != nil {
		return "", fmt.Errorf("verify token: %w", err)
	}
	defer func() {
		_ = resp.Body.Close()
	}()

	var ti tokenInfo
	if err := json.NewDecoder(resp.Body).Decode(&ti); err != nil {
		return "", fmt.Errorf("decode tokeninfo: %w", err)
	}
	if ti.ErrorDescription != "" {
		return "", fmt.Errorf("token info error: %s", ti.ErrorDescription)
	}
	if ti.Aud != s.clientID {
		return "", fmt.Errorf("invalid audience")
	}
	if ti.Sub == "" {
		return "", fmt.Errorf("no subject in token")
	}

	// create or fetch user
	u, err := s.users.CreateIfNotExists(ctx, ti.Sub)
	if err != nil {
		return "", fmt.Errorf("create/fetch user: %w", err)
	}

	return u.ID.String(), nil
}

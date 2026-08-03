package auth

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
)

func (s *Service) Authenticate(ctx context.Context, idToken string) (string, error) {
	if idToken == "" {
		return "", errors.New("empty id token")
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, "https://oauth2.googleapis.com/tokeninfo?id_token="+idToken, http.NoBody)
	if err != nil {
		return "", fmt.Errorf("http making request: %w", err)
	}
	resp, err := s.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("verify token: %w", err)
	}

	defer func() { _ = resp.Body.Close() }()

	var token tokenInfo
	if err := json.NewDecoder(resp.Body).Decode(&token); err != nil {
		return "", fmt.Errorf("decode token info: %w", err)
	}
	if token.ErrorDescription != "" {
		return "", fmt.Errorf("token info error: %s", token.ErrorDescription)
	}
	if token.Aud != s.clientID {
		return "", fmt.Errorf("invalid audience")
	}
	if token.Sub == "" {
		return "", fmt.Errorf("no subject in token")
	}

	u, err := s.userRepository.CreateIfNotExists(ctx, token.Sub)
	if err != nil {
		return "", fmt.Errorf("create/fetch user: %w", err)
	}

	return u.ID.String(), nil
}

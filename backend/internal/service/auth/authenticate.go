package auth

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
)

func (s *Service) Authenticate(ctx context.Context, idToken string) (userID, accessToken, email string, err error) {
	if idToken == "" {
		return "", "", "", errors.New("empty id token")
	}

	uri := s.tokenInfoURL + "?id_token=" + url.QueryEscape(idToken)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, uri, http.NoBody)
	if err != nil {
		return "", "", "", fmt.Errorf("making request: %w", err)
	}

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return "", "", "", fmt.Errorf("verify token: %w", err)
	}
	defer func() { _ = resp.Body.Close() }()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 4*1024))
		return "", "", "", fmt.Errorf(
			"tokeninfo responded with status %s: %s",
			resp.Status,
			strings.TrimSpace(string(body)),
		)
	}

	var token tokenInfo
	if err := json.NewDecoder(resp.Body).Decode(&token); err != nil {
		return "", "", "", fmt.Errorf("decode token info: %w", err)
	}
	if token.ErrorDescription != "" {
		return "", "", "", fmt.Errorf("token info error: %s", token.ErrorDescription)
	}
	if token.Iss != "accounts.google.com" && token.Iss != "https://accounts.google.com" {
		return "", "", "", fmt.Errorf("invalid issuer: %s", token.Iss)
	}
	if token.Aud != s.clientID && token.Aud != s.iosClientID {
		return "", "", "", fmt.Errorf("invalid audience")
	}
	if token.Sub == "" {
		return "", "", "", fmt.Errorf("no subject in token")
	}

	u, err := s.userRepository.CreateIfNotExists(ctx, token.Sub)
	if err != nil {
		return "", "", "", fmt.Errorf("create/fetch user: %w", err)
	}

	signed, err := s.jwtManager.Issue(u.ID.String())
	if err != nil {
		return "", "", "", fmt.Errorf("issue jwt: %w", err)
	}

	return u.ID.String(), signed, token.Email, nil
}

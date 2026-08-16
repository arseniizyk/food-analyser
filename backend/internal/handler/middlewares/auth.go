package middlewares

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"strings"

	"github.com/arseniizyk/food-analyser/backend/internal/handler/utils"
	jwtpkg "github.com/arseniizyk/food-analyser/backend/internal/service/jwt"
)

type ctxKey struct{}

func WithUserID(ctx context.Context, id string) context.Context {
	return context.WithValue(ctx, ctxKey{}, id)
}

func UserIDFromContext(ctx context.Context) (string, bool) {
	id, ok := ctx.Value(ctxKey{}).(string)
	return id, ok && id != ""
}

func RequireAuth(jwtManager *jwtpkg.Manager) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			userID, err := userIDFromRequest(r, jwtManager)
			if err != nil {
				utils.WriteError(w, r, http.StatusUnauthorized, "unauthorized")
				return
			}

			next.ServeHTTP(w, r.WithContext(WithUserID(r.Context(), userID)))
		})
	}
}

func OptionalAuth(jwtManager *jwtpkg.Manager) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			userID, err := userIDFromRequest(r, jwtManager)
			if err != nil {
				next.ServeHTTP(w, r)
				return
			}

			next.ServeHTTP(w, r.WithContext(WithUserID(r.Context(), userID)))
		})
	}
}

func JWTAuth(jwtManager *jwtpkg.Manager) func(http.Handler) http.Handler {
	require := RequireAuth(jwtManager)
	optional := OptionalAuth(jwtManager)

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			path := r.URL.Path
			switch {
			case path == "/api/v1/history":
				require(next).ServeHTTP(w, r)
			case strings.HasPrefix(path, "/api/v1/analyze/") || strings.HasPrefix(path, "/api/v1/analysis/"):
				optional(next).ServeHTTP(w, r)
			default:
				next.ServeHTTP(w, r)
			}
		})
	}
}

func userIDFromRequest(r *http.Request, jwtManager *jwtpkg.Manager) (string, error) {
	header := r.Header.Get("Authorization")
	if header == "" {
		return "", errors.New("missing authorization header")
	}

	parts := strings.SplitN(header, " ", 2)
	if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") || parts[1] == "" {
		return "", errors.New("invalid authorization header")
	}

	userID, err := jwtManager.Parse(parts[1])
	if err != nil {
		return "", fmt.Errorf("parse token: %w", err)
	}

	return userID, nil
}

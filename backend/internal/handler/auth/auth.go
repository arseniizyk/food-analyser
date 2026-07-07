package auth

import (
	"context"
	"encoding/json"
	"net/http"

	"github.com/arseniizyk/food-analyser/backend/internal/handler/utils"
)

type Service interface {
	Authenticate(ctx context.Context, idToken string) (string, error)
}

type Handler struct {
	authService Service
}

func New(authService Service) *Handler {
	return &Handler{authService: authService}
}

// AuthenticateWithGoogle TODO logs
func (ah *Handler) AuthenticateWithGoogle(w http.ResponseWriter, r *http.Request) {
	var body GoogleAuthRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		utils.WriteError(w, r, http.StatusBadRequest, "invalid body")
		return
	}

	userID, err := ah.authService.Authenticate(r.Context(), body.IDToken)
	if err != nil {
		utils.WriteError(w, r, http.StatusUnauthorized, "failed to authenticate")
		return
	}

	utils.WriteSuccess(w, r, http.StatusOK, GoogleAuthResponse{userID})
}

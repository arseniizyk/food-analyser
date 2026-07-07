package auth

import (
	"context"
	"encoding/json"
	"net/http"

	"github.com/arseniizyk/food-analyser/backend/internal/errs"
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

func (ah *Handler) AuthenticateWithGoogle(w http.ResponseWriter, r *http.Request) {
	var body struct {
		IdToken string `json:"id_token"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(errs.ErrorJSON{Code: http.StatusBadRequest, Message: "invalid body"})
		return
	}

	userID, err := ah.authService.Authenticate(r.Context(), body.IdToken)
	if err != nil {
		w.WriteHeader(http.StatusUnauthorized)
		_ = json.NewEncoder(w).Encode(errs.ErrorJSON{Code: http.StatusUnauthorized, Message: err.Error()})
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]string{"user_id": userID})
}

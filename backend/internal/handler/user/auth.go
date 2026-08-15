package user

import (
	"encoding/json"
	"net/http"

	"github.com/arseniizyk/food-analyser/backend/internal/handler/utils"
)

// AuthenticateWithGoogle TODO logs
func (h *Handler) AuthenticateWithGoogle(w http.ResponseWriter, r *http.Request) {
	var body googleAuthRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		utils.WriteError(w, r, http.StatusBadRequest, "invalid body")
		return
	}

	userID, err := h.authService.Authenticate(r.Context(), body.IDToken)
	if err != nil {
		utils.WriteError(w, r, http.StatusUnauthorized, "failed to authenticate")
		return
	}

	utils.WriteSuccess(w, r, http.StatusOK, googleAuthResponse{userID})
}

type googleAuthRequest struct {
	IDToken string `json:"id_token"`
}

type googleAuthResponse struct {
	UserID string `json:"user_id"`
}

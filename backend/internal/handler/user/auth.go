package user

import (
	"encoding/json"
	"errors"
	"net/http"

	"github.com/arseniizyk/food-analyser/backend/internal/handler/utils"
)

func (h *Handler) AuthenticateWithGoogle(w http.ResponseWriter, r *http.Request) {
	r.Body = http.MaxBytesReader(w, r.Body, 1*1024*1024)

	var body googleAuthRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		var maxErr *http.MaxBytesError
		if errors.As(err, &maxErr) {
			utils.WriteError(w, r, http.StatusRequestEntityTooLarge, "request body is too large")
			return
		}
		utils.WriteError(w, r, http.StatusBadRequest, "invalid body")
		return
	}

	userID, accessToken, email, err := h.authService.Authenticate(r.Context(), body.IDToken)
	if err != nil {
		h.logger.Error("failed to authenticate with google", "error", err)
		utils.WriteError(w, r, http.StatusUnauthorized, "failed to authenticate")
		return
	}

	h.logger.Info("user authenticated with google", "user_id", userID)

	utils.WriteSuccess(w, r, http.StatusOK, googleAuthResponse{
		UserID:      userID,
		AccessToken: accessToken,
		Email:       email,
	})
}

type googleAuthRequest struct {
	IDToken string `json:"id_token"`
}

type googleAuthResponse struct {
	UserID      string `json:"user_id"`
	AccessToken string `json:"access_token"`
	Email       string `json:"email"`
}

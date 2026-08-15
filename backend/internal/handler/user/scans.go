package user

import (
	"net/http"

	"github.com/arseniizyk/food-analyser/backend/internal/handler/middlewares"
	"github.com/arseniizyk/food-analyser/backend/internal/handler/utils"
)

func (h *Handler) GetUserScans(w http.ResponseWriter, r *http.Request) {
	uid, ok := middlewares.UserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, http.StatusUnauthorized, "unauthorized")
		return
	}

	scans, err := h.userService.GetScans(r.Context(), uid)
	if err != nil {
		h.logger.Error("failed to get user scans", "user_id", uid, "error", err)
		utils.WriteError(w, r, http.StatusInternalServerError, err.Error())
		return
	}

	utils.WriteSuccess(w, r, http.StatusOK, scans)
}

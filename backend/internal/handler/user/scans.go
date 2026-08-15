package user

import (
	"errors"
	"net/http"

	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/arseniizyk/food-analyser/backend/internal/errs"
	"github.com/arseniizyk/food-analyser/backend/internal/handler/utils"
)

func (h *Handler) GetUserScans(w http.ResponseWriter, r *http.Request, userId openapi_types.UUID) {
	uid := userId.String()

	if uid == "" {
		utils.WriteError(w, r, http.StatusBadRequest, "Invalid User ID")
		return
	}

	scans, err := h.userService.GetScans(r.Context(), uid)
	if err != nil {
		if errors.Is(err, errs.ErrUserNotFound) {
			utils.WriteError(w, r, http.StatusNotFound, "User not found")
		}
		utils.WriteError(w, r, http.StatusInternalServerError, err.Error())
	}

	utils.WriteSuccess(w, r, http.StatusOK, scans)
}

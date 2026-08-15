package analysis

import (
	"context"
	"errors"
	"net/http"
	"time"

	"github.com/arseniizyk/food-analyser/backend/internal/errs"
	"github.com/arseniizyk/food-analyser/backend/internal/handler/utils"
)

func (h *Handler) Analyze(w http.ResponseWriter, r *http.Request, barcode string) {
	ctx, cancel := context.WithTimeout(r.Context(), 1*time.Minute)
	defer cancel()

	file, _, err := r.FormFile("image")
	if err != nil {
		utils.WriteError(w, r, http.StatusBadRequest, "invalid file")
		return
	}
	defer func() { _ = file.Close() }()

	userID := r.FormValue("user_id")

	analysis, err := h.service.Analyze(ctx, barcode, file)
	if err != nil {
		if errors.Is(err, errs.ErrRecognizeFromImage) {
			utils.WriteError(w, r, http.StatusBadRequest, "can't recognize text from image")
			return
		}

		if errors.Is(err, errs.ErrAnalysingNutrition) {
			utils.WriteError(w, r, http.StatusBadGateway, "llm service error")
			return
		}

		utils.WriteError(w, r, http.StatusInternalServerError, "unknown error")
		return
	}

	if userID != "" {
		_ = h.userService.AddScan(ctx, userID, barcode)
	}

	utils.WriteSuccess(w, r, http.StatusOK, analysis)
}

package analysis

import (
	"context"
	"errors"
	"net/http"
	"time"

	"github.com/arseniizyk/food-analyser/backend/internal/errs"
	"github.com/arseniizyk/food-analyser/backend/internal/handler/middlewares"
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

	if userID, ok := middlewares.UserIDFromContext(r.Context()); ok {
		if err := h.userService.AddScan(ctx, userID, barcode); err != nil {
			h.logger.Error("failed to add scan", "user_id", userID, "barcode", barcode, "error", err)
		}
	}

	utils.WriteSuccess(w, r, http.StatusOK, analysis)
}

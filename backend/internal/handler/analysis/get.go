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

func (h *Handler) GetAnalysisByBarcode(w http.ResponseWriter, r *http.Request, barcode string) {
	ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
	defer cancel()

	analysis, err := h.service.GetAnalysisByBarcode(ctx, barcode)
	if err != nil {
		if errors.Is(err, errs.ErrAnalysisNotFound) {
			utils.WriteError(w, r, http.StatusNotFound, "analysis was not found")
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

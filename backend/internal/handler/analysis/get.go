package analysis

import (
	"context"
	"errors"
	"net/http"
	"time"

	"github.com/arseniizyk/food-analyser/backend/internal/errs"
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

	// h.userService.AddScan(ctx, ) TODO: получение UserID из JWT и сохранение в repository
	utils.WriteSuccess(w, r, http.StatusOK, analysis)
}

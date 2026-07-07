package product

import (
	"context"
	"errors"
	"io"
	"net/http"
	"time"

	"github.com/arseniizyk/food-analyser/backend/internal/errs"
	"github.com/arseniizyk/food-analyser/backend/internal/handler/utils"
	"github.com/arseniizyk/food-analyser/backend/internal/models"
)

type Service interface {
	GetAnalysisByBarcode(ctx context.Context, barcode string) (*models.Analysis, error)
	AnalyzeProduct(ctx context.Context, barcode string, image io.Reader) (*models.Analysis, error)
}

type Handler struct {
	Service Service
}

func New(service Service) *Handler {
	return &Handler{Service: service}
}

func (h *Handler) AnalyzeProduct(w http.ResponseWriter, r *http.Request, barcode string) {
	ctx, cancel := context.WithTimeout(r.Context(), 20*time.Second)
	defer cancel()

	file, _, err := r.FormFile("file")
	if err != nil {
		utils.WriteError(w, r, http.StatusBadRequest, "invalid file")
		return
	}
	defer func() { _ = file.Close() }()

	// Optional user_id is accepted by the spec for future server-side history storage.
	_ = r.FormValue("user_id")

	analysis, err := h.Service.AnalyzeProduct(ctx, barcode, file)
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

	utils.WriteSuccess(w, r, http.StatusOK, analysis)
}

func (h *Handler) GetAnalysisByBarcode(w http.ResponseWriter, r *http.Request, barcode string) {
	ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
	defer cancel()

	analysis, err := h.Service.GetAnalysisByBarcode(ctx, barcode)
	if err != nil {
		if errors.Is(err, errs.ErrAnalysisNotFound) {
			utils.WriteError(w, r, http.StatusNotFound, "analysis was not found")
			return
		}

		utils.WriteError(w, r, http.StatusInternalServerError, "unknown error")
		return
	}

	utils.WriteSuccess(w, r, http.StatusOK, analysis)
}

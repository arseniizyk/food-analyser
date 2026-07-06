package product

import (
	"context"
	"errors"
	"io"
	"net/http"
	"time"

	"github.com/go-chi/render"

	"github.com/arseniizyk/food-analyser/backend/internal/errs"
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
		writeError(w, r, http.StatusBadRequest, "invalid file")
		return
	}
	defer func() { _ = file.Close() }()

	analysis, err := h.Service.AnalyzeProduct(ctx, barcode, file)
	if err != nil {
		if errors.Is(err, errs.ErrRecognizeFromImage) {
			writeError(w, r, http.StatusBadRequest, "can't recognize text from image")
			return
		}

		if errors.Is(err, errs.ErrAnalysingNutrition) {
			writeError(w, r, http.StatusBadGateway, "llm service error")
			return
		}

		writeError(w, r, http.StatusInternalServerError, "unknown error")
		return
	}

	writeSuccess(w, r, http.StatusOK, analysis)
}

func (h *Handler) GetAnalysisByBarcode(w http.ResponseWriter, r *http.Request, barcode string) {
	ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
	defer cancel()

	analysis, err := h.Service.GetAnalysisByBarcode(ctx, barcode)
	if err != nil {
		if errors.Is(err, errs.ErrAnalysisNotFound) {
			writeError(w, r, http.StatusNotFound, "analysis was not found")
			return
		}

		writeError(w, r, http.StatusInternalServerError, "unknown error")
		return
	}

	writeSuccess(w, r, http.StatusOK, analysis)
}

func writeSuccess(w http.ResponseWriter, r *http.Request, status int, dataJSON any) {
	render.Status(r, status)
	render.JSON(w, r, dataJSON)
}

func writeError(w http.ResponseWriter, r *http.Request, status int, msg string) {
	render.Status(r, status)
	render.JSON(w, r, models.ErrorJSON{
		Code:    status,
		Message: msg,
	})
}

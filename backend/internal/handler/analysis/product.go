package analysis

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
	Analyze(ctx context.Context, barcode string, image io.Reader) (*models.Analysis, error)
}

type UserService interface {
	AddScan(ctx context.Context, userID, barcode string) error
}

type Handler struct {
	userService UserService
	service     Service
}

func New(service Service, userService UserService) *Handler {
	return &Handler{
		service:     service,
		userService: userService,
	}
}

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

	utils.WriteSuccess(w, r, http.StatusOK, analysis)
}

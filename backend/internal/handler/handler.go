package handler

import "net/http"

type AnalysisHandler interface {
	Analyze(w http.ResponseWriter, r *http.Request, barcode string)
	GetAnalysisByBarcode(w http.ResponseWriter, r *http.Request, barcode string)
}

type AuthHandler interface {
	AuthenticateWithGoogle(w http.ResponseWriter, r *http.Request)
}

type Handler struct {
	AnalysisHandler
	AuthHandler
}

func NewHandler(authHandler AuthHandler, productHandler AnalysisHandler) *Handler {
	return &Handler{
		AnalysisHandler: productHandler,
		AuthHandler:     authHandler,
	}
}

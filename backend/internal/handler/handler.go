package handler

import "net/http"

type ProductHandler interface {
	AnalyzeProduct(w http.ResponseWriter, r *http.Request, barcode string)
	GetAnalysisByBarcode(w http.ResponseWriter, r *http.Request, barcode string)
}

type AuthHandler interface {
	AuthenticateWithGoogle(w http.ResponseWriter, r *http.Request)
}

type Handler struct {
	ProductHandler
	AuthHandler
}

func NewHandler(authHandler AuthHandler, productHandler ProductHandler) *Handler {
	return &Handler{
		ProductHandler: productHandler,
		AuthHandler:    authHandler,
	}
}

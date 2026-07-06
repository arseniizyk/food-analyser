package product

import "net/http"

type Service interface{}

type Handler struct {
	Service Service
}

func New(service Service) *Handler {
	return &Handler{Service: service}
}

func (ph *Handler) AnalyzeProduct(w http.ResponseWriter, r *http.Request, barcode string) {
	panic("not implemented")
}

func (ph *Handler) GetAnalysisByBarcode(w http.ResponseWriter, r *http.Request, barcode string) {
	panic("not implemented")
}

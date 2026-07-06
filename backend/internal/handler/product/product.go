package product

import "net/http"

type ProductService interface {
}

type ProductHandler struct {
	productService ProductService
}

func New(productService *ProductService) *ProductHandler {
	return &ProductHandler{productService: productService}
}

func (ph *ProductHandler) AnalyzeProduct(w http.ResponseWriter, r *http.Request, barcode string) {
	panic("not implemented")
}

func (ph *ProductHandler) GetAnalysisByBarcode(w http.ResponseWriter, r *http.Request, barcode string) {
	panic("not implemented")
}

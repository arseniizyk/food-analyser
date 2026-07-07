package utils

import (
	"net/http"

	"github.com/arseniizyk/food-analyser/backend/internal/errs"
	"github.com/go-chi/render"
)

func WriteSuccess(w http.ResponseWriter, r *http.Request, status int, dataJSON any) {
	render.Status(r, status)
	render.JSON(w, r, dataJSON)
}

func WriteError(w http.ResponseWriter, r *http.Request, status int, msg string) {
	render.Status(r, status)
	render.JSON(w, r, errs.ErrorJSON{
		Code:    status,
		Message: msg,
	})
}

package auth

import "net/http"

type Service interface{}

type Handler struct {
	authService Service
}

func New(authService Service) *Handler {
	return &Handler{authService: authService}
}

func (ah *Handler) AuthenticateWithGoogle(w http.ResponseWriter, r *http.Request) {
	panic("not implemented")
}

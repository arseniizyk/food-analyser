package auth

import "net/http"

type AuthService interface{}

type AuthHandler struct {
	authService AuthService
}

func New(authService AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

func (ah *AuthHandler) AuthenticateWithGoogle(w http.ResponseWriter, r *http.Request) {
	panic("not implemented")
}

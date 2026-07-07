package auth

type GoogleAuthRequest struct {
	IDToken string `json:"id_token"`
}

type GoogleAuthResponse struct {
	UserID string `json:"user_id"`
}

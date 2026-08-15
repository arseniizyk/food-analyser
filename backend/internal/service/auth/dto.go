package auth

type tokenInfo struct {
	Aud              string `json:"aud"`
	Sub              string `json:"sub"`
	Email            string `json:"email"`
	ErrorDescription string `json:"error_description"`
}

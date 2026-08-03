package auth

type tokenInfo struct {
	Aud              string `json:"aud"`
	Sub              string `json:"sub"`
	ErrorDescription string `json:"error_description"`
}

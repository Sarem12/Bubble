package response

type AuthResponse struct {
	SessionToken string `json:"session_token"`
}

type VerifySessionResponse struct {
	AccessToken string `json:"access_token"`
}

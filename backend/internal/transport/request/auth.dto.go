package request

type RegisterRequest struct {
	Username	string	`json:"username"`
	FirstName	string	`json:"first_name"`
	LastName	string	`json:"last_name"`
	Bio		string	`json:"bio"`
	Birthday	string	`json:"birthday"`
	Password	string	`json:"password"`
	DeviceID	string	`json:"device_id"`
	DeviceName	string	`json:"device_name"`
}

type LoginRequest struct {
	Provider	string	`json:"provider"`
	Identifier	string	`json:"identifier"`
	Password	string	`json:"password"`
	DeviceID	string	`json:"device_id"`
	DeviceName	string	`json:"device_name"`
}

type AddProviderRequest struct {
	Password	string	`json:"password"`
	DeviceID	string	`json:"device_id"`
	DeviceName	string	`json:"device_name"`
}

type GoogleLoginRequest struct {
	IDToken		string	`json:"id_token"`
	Username	string	`json:"username"`
	FirstName	string	`json:"first_name"`
	LastName	string	`json:"last_name"`
	DeviceID	string	`json:"device_id"`
	DeviceName	string	`json:"device_name"`
}

type ChangePasswordRequest struct {
	OldPassword	string	`json:"old_password"`
	NewPassword	string	`json:"new_password"`
}

type DeleteAccountRequest struct {
	Password string `json:"password"`
}

type SendOTPRequest struct {
	Provider	string	`json:"provider"`
	Identifier	string	`json:"identifier"`
	Purpose		string	`json:"purpose"`
}

type VerifyOTPRequest struct {
	Identifier	string	`json:"identifier"`
	Code		string	`json:"code"`
}

type ResetPasswordRequest struct {
	NewPassword string `json:"new_password"`
}

type VerifySessionRequest struct {
	SessionToken string `json:"session_token"`
	DeviceID     string `json:"device_id"`
	DeviceName   string `json:"device_name"`
}

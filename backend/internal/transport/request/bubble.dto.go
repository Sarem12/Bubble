package request

type CreateBubbleRequest struct {
	Name		string	`json:"name"`
	Description	string	`json:"description"`
	Type		string	`json:"type"`
	MemberKey	string	`json:"member_key,omitempty"`
}


type JoinBubbleRequest struct {
	MemberKey *string `json:"member_key,omitempty"`
}

type InviteUserRequest struct {
	TargetUserID string `json:"target_user_id"`
}

package domain

import (
	"context"
)

type UserSearchResult struct {
	ID		string	`json:"id"`
	Username	string	`json:"username"`
	Bio		string	`json:"bio"`
	Type		string	`json:"type"`
}

type BubbleSearchResult struct {
	ID		string	`json:"id"`
	Name		string	`json:"name"`
	Description	string	`json:"description"`
	Type		string	`json:"type"`
}

type PostSearchResult struct {
	ID		string	`json:"id"`
	Content		string	`json:"content"`
	LikesCount	int	`json:"likes_count"`
	BubbleName	string	`json:"bubble_name,omitempty"`
}

type AllSearchResults struct {
	Users	[]*UserSearchResult	`json:"users"`
	Bubbles	[]*BubbleSearchResult	`json:"bubbles"`
	Posts	[]*PostSearchResult	`json:"posts"`
}

type SearchRepository interface {
	SearchUsers(ctx context.Context, query string, direct bool, limit int) ([]*UserSearchResult, error)
	SearchBubbles(ctx context.Context, query string, direct bool, limit int) ([]*BubbleSearchResult, error)
	SearchPosts(ctx context.Context, query string, limit int) ([]*PostSearchResult, error)
	GetTopPostsForBubble(ctx context.Context, bubbleName string, limit int) ([]*PostSearchResult, error)
}

type SearchService interface {
	SearchAll(ctx context.Context, query string, limit int) (*AllSearchResults, error)
	SearchUsers(ctx context.Context, query string, limit int) ([]*UserSearchResult, error)
	SearchBubbles(ctx context.Context, query string, limit int) ([]*BubbleSearchResult, error)
	SearchPosts(ctx context.Context, query string, limit int) ([]*PostSearchResult, error)
	GetTopPostsForBubble(ctx context.Context, bubbleName string, limit int) ([]*PostSearchResult, error)
}

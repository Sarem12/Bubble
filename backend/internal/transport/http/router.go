package http

import (
	postman "bubble-api/internal/devtools"
	"bubble-api/internal/domain"
	"bubble-api/internal/transport/request"
	"os"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/limiter"
)

func SetupRoutes(app *fiber.App, tokenService domain.TokenService, userHandler *userHandler, authHandler *authHandler, bubbleHandler *bubbleHandler, postHandler *postHandler, replyHandler *replyHandler, interactionHandler *postInteractionHandler,
	friendshipHandler *friendshipHandler, searchHandler *searchHandler, feedHandler *feedHandler, mediaHandler *mediaHandler, convHandler *conversationHandler, activityHandler *activityHandler) {

	api := app.Group("/api")

	users := api.Group("/users")
	postman.BindDTO(users.Post("/", userHandler.CreateUser), request.CreateUserRequest{})

	users.Get("/username/:username", userHandler.GetUserByUsername)
	users.Use("/me", RequireAuth(tokenService))
	users.Get("/me", userHandler.GetMyProfile)
	users.Get("/me/settings", userHandler.GetSettings)
	postman.BindDTO(users.Put("/me", userHandler.UpdateUser), request.UpdateUserRequest{})
	postman.BindDTO(users.Patch("/me/settings", userHandler.UpdateSettings), request.UpdateUserSettingsRequest{})

	users.Post("/me/profile-picture", userHandler.UploadProfilePicture)
	users.Delete("/me", userHandler.DeleteUser)

	users.Put("/:id/last-active", userHandler.UpdateLastActive)
	users.Get("/:id", userHandler.GetUserByID)

	auth := api.Group("/auth")
	postman.BindDTO(auth.Post("/register", authHandler.RegisterAnAccount), request.RegisterRequest{})
	postman.BindDTO(auth.Post("/verify-session", authHandler.VerifySession), request.VerifySessionRequest{})
	postman.BindDTO(auth.Post("/login", authHandler.LoginToAccount), request.LoginRequest{})

	otpLimiter10Min := limiter.New(limiter.Config{
		Next: func(c *fiber.Ctx) bool {
			return os.Getenv("APP_ENV") == "development"
		},
		Max:          5,
		Expiration:   10 * time.Minute,
		KeyGenerator: func(c *fiber.Ctx) string { return c.IP() },
		LimitReached: func(c *fiber.Ctx) error {
			return c.Status(fiber.StatusTooManyRequests).JSON(fiber.Map{"error": "Too many requests. Please wait 10 minutes."})
		},
	})

	otpLimiter24Hour := limiter.New(limiter.Config{
		Next: func(c *fiber.Ctx) bool {
			return os.Getenv("APP_ENV") == "development"
		},
		Max:          30,
		Expiration:   24 * time.Hour,
		KeyGenerator: func(c *fiber.Ctx) string { return c.IP() },
		LimitReached: func(c *fiber.Ctx) error {
			return c.Status(fiber.StatusTooManyRequests).JSON(fiber.Map{"error": "Daily limit reached (30/day). Try again tomorrow."})
		},
	})

	postman.BindDTO(auth.Post("/send-otp", otpLimiter10Min, otpLimiter24Hour, authHandler.SendOTP), request.SendOTPRequest{})
	postman.BindDTO(auth.Post("/verify-otp", authHandler.VerifyOTP), request.VerifyOTPRequest{})
	postman.BindDTO(auth.Post("/reset-password", authHandler.ResetPassword), request.ResetPasswordRequest{})
	postman.BindDTO(auth.Post("/google", authHandler.LoginWithGoogle), request.GoogleLoginRequest{})

	auth.Use("/me", RequireAuth(tokenService))
	auth.Get("/me/sessions", authHandler.GetSessions)
	auth.Delete("/me/sessions/:id", authHandler.RevokeSession)
	postman.BindDTO(auth.Put("/me/password", authHandler.ChangePassword), request.ChangePasswordRequest{})
	postman.BindDTO(auth.Post("/me/provider", authHandler.AddProviderToAnAccount), request.AddProviderRequest{})
	postman.BindDTO(auth.Delete("/me", authHandler.DeleteAccount), request.DeleteAccountRequest{})

	bubbles := api.Group("/bubbles")
	bubbles.Get("/", OptionalAuth(tokenService), bubbleHandler.GetBubbles)
	bubbles.Get("/user/:id", OptionalAuth(tokenService), bubbleHandler.GetUserBubbles)
	bubbles.Get("/name/:name", OptionalAuth(tokenService), bubbleHandler.GetBubbleByName)
	bubblesProtected := bubbles.Group("/")
	bubblesProtected.Use(RequireAuth(tokenService))
	bubblesProtected.Patch("/:id/notifications", bubbleHandler.UpdateNotifications)
	postman.BindDTO(bubblesProtected.Post("/", bubbleHandler.CreateBubble), request.CreateBubbleRequest{})

	friends := api.Group("/friends", RequireAuth(tokenService))
	postman.BindDTO(friends.Post("/request", friendshipHandler.SendRequest), request.SendFriendRequest{})
	friends.Post("/request/:id/accept", friendshipHandler.AcceptRequest)
	friends.Post("/request/:id/decline", friendshipHandler.DeclineRequest)
	friends.Delete("/:id", friendshipHandler.RemoveFriend)
	friends.Post("/:id/block", friendshipHandler.BlockUser)
	friends.Delete("/:id/block", friendshipHandler.UnblockUser)
	postman.BindDTO(friends.Patch("/:id/settings", friendshipHandler.UpdateSettings), request.UpdateFriendshipSettingsRequest{})
	friends.Get("/", friendshipHandler.GetFriends)
	friends.Get("/blocked", friendshipHandler.GetBlocked)
	friends.Get("/requests", friendshipHandler.GetRequests)

	postman.BindDTO(bubblesProtected.Post("/:id/join", bubbleHandler.JoinBubble), request.JoinBubbleRequest{})
	bubblesProtected.Delete("/:id/leave", bubbleHandler.LeaveBubble)

	postman.BindDTO(bubblesProtected.Post("/:id/invite", bubbleHandler.InviteToBubble), request.InviteUserRequest{})
	bubblesProtected.Post("/invitations/:id/accept", bubbleHandler.AcceptInvitation)
	bubblesProtected.Post("/invitations/:id/decline", bubbleHandler.DeclineInvitation)

	bubblesProtected.Get("/:id/members", bubbleHandler.GetMembers)

	posts := api.Group("/posts")
	posts.Get("/:id", OptionalAuth(tokenService), postHandler.GetPostByID)
	posts.Get("/:id/replies", OptionalAuth(tokenService), replyHandler.GetRepliesByPostID)
	posts.Get("/:id/interactions", OptionalAuth(tokenService), interactionHandler.GetInteractionsByPost)

	postsProtected := posts.Group("/")
	postsProtected.Use(RequireAuth(tokenService))
	postsProtected.Get("/me/notifications", postHandler.GetMyNotificationSettings)
	postsProtected.Patch("/:id/notifications", postHandler.UpdateNotificationSettings)
	postman.BindDTO(postsProtected.Post("/", postHandler.CreatePost), request.CreatePostRequest{})
	postman.BindDTO(postsProtected.Put("/:id", postHandler.UpdatePost), request.UpdatePostRequest{})
	postsProtected.Delete("/:id", postHandler.DeletePost)
	postsProtected.Post("/:id/interactions/share", interactionHandler.SharePost)
	postman.BindDTO(postsProtected.Post("/:id/replies", replyHandler.CreateReply), request.CreateReplyRequest{})
	postman.BindDTO(postsProtected.Put("/:id/interactions/react", interactionHandler.ReactToPost), request.ReactToPostRequest{})
	postman.BindDTO(postsProtected.Put("/:id/interactions/save", interactionHandler.SavePost), request.SavePostRequest{})
	postsProtected.Put("/:id/interactions/view", interactionHandler.ViewPost)
	postsProtected.Delete("/:id/interactions/react", interactionHandler.RemoveReaction)

	replies := api.Group("/replies")
	replies.Get("/:id", OptionalAuth(tokenService), replyHandler.GetReplyByID)

	repliesProtected := replies.Group("/")
	repliesProtected.Use(RequireAuth(tokenService))
	postman.BindDTO(repliesProtected.Put("/:id", replyHandler.UpdateReply), request.UpdateReplyRequest{})
	repliesProtected.Delete("/:id", replyHandler.DeleteReply)
	postman.BindDTO(repliesProtected.Put("/:id/interactions/react", replyHandler.ReactToReply), request.ReactToReplyRequest{})
	repliesProtected.Delete("/:id/interactions/react", replyHandler.RemoveReaction)
	postman.BindDTO(repliesProtected.Put("/:id/react", replyHandler.ReactToReply), request.ReactToReplyRequest{})
	repliesProtected.Delete("/:id/react", replyHandler.RemoveReaction)

	search := api.Group("/search")
	search.Get("/all", OptionalAuth(tokenService), searchHandler.SearchAll)
	search.Get("/users", OptionalAuth(tokenService), searchHandler.SearchUsers)
	search.Get("/bubbles", OptionalAuth(tokenService), searchHandler.SearchBubbles)
	search.Get("/posts", OptionalAuth(tokenService), searchHandler.SearchPosts)
	search.Get("/bubbles/:bubbleName/top", OptionalAuth(tokenService), searchHandler.GetTopPostsForBubble)

	feed := api.Group("/feed")
	feed.Use(RequireAuth(tokenService))
	feed.Get("/", feedHandler.GetFeed)
	feed.Get("/explore", feedHandler.GetExploreFeed)
	feed.Get("/user/:id", feedHandler.GetUserFeed)
	feed.Get("/posts/:id", feedHandler.GetFeedItemByID)

	media := api.Group("/media")
	media.Use(RequireAuth(tokenService))
	media.Post("/upload", mediaHandler.UploadMedia)
	media.Get("/:filename", mediaHandler.ServeMedia)

	convs := api.Group("/conversations", RequireAuth(tokenService))
	convs.Post("/", convHandler.CreateOrGetConversation)
	convs.Get("/", convHandler.GetConversations)

	activity := api.Group("/activity", RequireAuth(tokenService))
	activity.Get("/", activityHandler.GetActivities)
	activity.Get("", activityHandler.GetActivities)
	activity.Get("/requests", activityHandler.GetPendingFriendRequests)

	notifications := api.Group("/notifications", RequireAuth(tokenService))
	notifications.Get("/", activityHandler.GetActivities)
	notifications.Get("", activityHandler.GetActivities)
	notifications.Get("/requests", activityHandler.GetPendingFriendRequests)
}

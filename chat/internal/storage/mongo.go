package storage

import (
	"context"
	"time"

	"chat/internal/config"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type LastMessageInfo struct {
	SenderID string    `json:"sender_id" bson:"sender_id"`
	Content  string    `json:"content" bson:"content"`
	SentAt   time.Time `json:"sent_at" bson:"sent_at"`
}

type Conversation struct {
	ID           string           `json:"id" bson:"_id"`
	Participants []string         `json:"participants" bson:"participants"`
	LastMessage  *LastMessageInfo `json:"last_message" bson:"last_message"`
	UpdatedAt    time.Time        `json:"updated_at" bson:"updated_at"`
}

type Reaction struct {
	UserID string `json:"user_id" bson:"user_id"`
	Emoji  string `json:"emoji" bson:"emoji"`
}

type Message struct {
	ID             primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	ConversationID string             `json:"conversation_id" bson:"conversation_id"`
	Topic          string             `json:"topic,omitempty" bson:"topic,omitempty"`
	SenderID       string             `json:"sender_id" bson:"sender_id"`
	RecipientID    string             `json:"recipient_id" bson:"recipient_id"`
	Content        string             `json:"content" bson:"content"`
	CreatedAt      time.Time          `json:"created_at" bson:"created_at"`
	ReadAt         *time.Time         `json:"read_at,omitempty" bson:"read_at,omitempty"`
	Reactions      []Reaction         `json:"reactions,omitempty" bson:"reactions,omitempty"`
}

func SaveMessage(ctx context.Context, msg *Message) error {
	db := config.MongoClient.Database("bubble")
	messagesCol := db.Collection("messages")
	convsCol := db.Collection("conversations")

	if msg.ID.IsZero() {
		msg.ID = primitive.NewObjectID()
	}

	// Insert Message
	_, err := messagesCol.InsertOne(ctx, msg)
	if err != nil {
		return err
	}

	// Upsert Conversation
	lastMsg := &LastMessageInfo{
		SenderID: msg.SenderID,
		Content:  msg.Content,
		SentAt:   msg.CreatedAt,
	}

	update := bson.M{
		"$set": bson.M{
			"last_message": lastMsg,
			"updated_at":   msg.CreatedAt,
		},
		"$addToSet": bson.M{
			"participants": bson.M{"$each": []string{msg.SenderID, msg.RecipientID}},
		},
	}
	opts := options.Update().SetUpsert(true)

	_, err = convsCol.UpdateByID(ctx, msg.ConversationID, update, opts)
	return err
}

func GetConversations(ctx context.Context, userID string) ([]Conversation, error) {
	db := config.MongoClient.Database("bubble")
	col := db.Collection("conversations")

	filter := bson.M{"participants": userID}
	opts := options.Find().SetSort(bson.D{{Key: "updated_at", Value: -1}})

	cursor, err := col.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var convs []Conversation
	if err = cursor.All(ctx, &convs); err != nil {
		return nil, err
	}
	return convs, nil
}

func GetMessages(ctx context.Context, conversationID string, limit int64) ([]Message, error) {
	db := config.MongoClient.Database("bubble")
	col := db.Collection("messages")

	filter := bson.M{"conversation_id": conversationID}
	opts := options.Find().SetSort(bson.D{{Key: "created_at", Value: -1}}).SetLimit(limit)

	cursor, err := col.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var msgs []Message
	if err = cursor.All(ctx, &msgs); err != nil {
		return nil, err
	}
	return msgs, nil
}

func GetLastMessages(ctx context.Context, conversationIDs []string) (map[string]*LastMessageInfo, error) {
	db := config.MongoClient.Database("bubble")
	col := db.Collection("conversations")

	filter := bson.M{"_id": bson.M{"$in": conversationIDs}}
	cursor, err := col.Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var convs []Conversation
	if err = cursor.All(ctx, &convs); err != nil {
		return nil, err
	}

	result := make(map[string]*LastMessageInfo)
	for _, c := range convs {
		result[c.ID] = c.LastMessage
	}

	return result, nil
}

func MarkMessagesAsRead(ctx context.Context, conversationID string, readerID string) (time.Time, error) {
	db := config.MongoClient.Database("bubble")
	col := db.Collection("messages")

	now := time.Now()
	filter := bson.M{
		"conversation_id": conversationID,
		"sender_id":       bson.M{"$ne": readerID},
		"$or": []bson.M{
			{"read_at": bson.M{"$exists": false}},
			{"read_at": nil},
		},
	}
	
	update := bson.M{
		"$set": bson.M{"read_at": now},
	}

	_, err := col.UpdateMany(ctx, filter, update)
	return now, err
}

func GetConversationByID(ctx context.Context, conversationID string) (*Conversation, error) {
	db := config.MongoClient.Database("bubble")
	col := db.Collection("conversations")
	var conv Conversation
	err := col.FindOne(ctx, bson.M{"_id": conversationID}).Decode(&conv)
	if err != nil {
		return nil, err
	}
	return &conv, nil
}

func DeleteMessage(ctx context.Context, messageID string, conversationID string) error {
	db := config.MongoClient.Database("bubble")
	col := db.Collection("messages")
	convsCol := db.Collection("conversations")

	objID, err := primitive.ObjectIDFromHex(messageID)
	if err != nil {
		return err
	}

	_, err = col.DeleteOne(ctx, bson.M{"_id": objID})
	if err != nil {
		return err
	}

	// Update conversation's last message
	var latest Message
	findOpts := options.FindOne().SetSort(bson.D{{Key: "created_at", Value: -1}})
	err = col.FindOne(ctx, bson.M{"conversation_id": conversationID}, findOpts).Decode(&latest)
	if err == nil {
		convsCol.UpdateByID(ctx, conversationID, bson.M{
			"$set": bson.M{
				"last_message": LastMessageInfo{
					SenderID: latest.SenderID,
					Content:  latest.Content,
					SentAt:   latest.CreatedAt,
				},
				"updated_at": latest.CreatedAt,
			},
		})
	} else {
		convsCol.UpdateByID(ctx, conversationID, bson.M{
			"$set": bson.M{
				"last_message": nil,
			},
		})
	}

	return nil
}

func ToggleReaction(ctx context.Context, messageID string, userID string, emoji string) ([]Reaction, error) {
	db := config.MongoClient.Database("bubble")
	col := db.Collection("messages")

	objID, err := primitive.ObjectIDFromHex(messageID)
	if err != nil {
		return nil, err
	}

	var msg Message
	err = col.FindOne(ctx, bson.M{"_id": objID}).Decode(&msg)
	if err != nil {
		return nil, err
	}

	reactions := msg.Reactions
	foundIndex := -1
	for i, r := range reactions {
		if r.UserID == userID {
			foundIndex = i
			break
		}
	}

	if foundIndex >= 0 {
		if reactions[foundIndex].Emoji == emoji {
			// Remove reaction
			reactions = append(reactions[:foundIndex], reactions[foundIndex+1:]...)
		} else {
			// Change reaction
			reactions[foundIndex].Emoji = emoji
		}
	} else {
		// Add reaction
		reactions = append(reactions, Reaction{
			UserID: userID,
			Emoji:  emoji,
		})
	}

	_, err = col.UpdateOne(ctx, bson.M{"_id": objID}, bson.M{
		"$set": bson.M{"reactions": reactions},
	})
	if err != nil {
		return nil, err
	}

	return reactions, nil
}

func DeleteConversation(ctx context.Context, conversationID string) error {
	db := config.MongoClient.Database("bubble")
	messagesCol := db.Collection("messages")
	convsCol := db.Collection("conversations")

	_, err := messagesCol.DeleteMany(ctx, bson.M{"conversation_id": conversationID})
	if err != nil {
		return err
	}

	_, err = convsCol.DeleteOne(ctx, bson.M{"_id": conversationID})
	return err
}

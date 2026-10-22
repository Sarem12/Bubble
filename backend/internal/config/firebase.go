package config

import (
	"context"
	"log"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"
)

var FCMClient *messaging.Client

func InitFirebase() error {
	ctx := context.Background()
	// Points to the firebase.json you just created in the backend folder
	opt := option.WithCredentialsFile("firebase.json")
	app, err := firebase.NewApp(ctx, nil, opt)
	if err != nil {
		return err
	}

	client, err := app.Messaging(ctx)
	if err != nil {
		return err
	}

	FCMClient = client
	log.Println("Firebase Admin SDK initialized successfully")
	return nil
}

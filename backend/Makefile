include .env
export

DB_URL ?= postgres://postgres:mysecretpassword@localhost:5432/myappdb?sslmode=disable

migrateup:
	migrate -path migrations -database "$(DB_URL)" up

migratedown:
	migrate -path migrations -database "$(DB_URL)" down -all

reset-db:
	migrate -path migrations -database "$(DB_URL)" down -all
	migrate -path migrations -database "$(DB_URL)" up

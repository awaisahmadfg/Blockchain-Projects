package main

import (
	"fmt"
	"log"

	"github.com/awaisahmadfg/go-clover-demo/database"
	"github.com/awaisahmadfg/go-clover-demo/models"
)

func main() {
	// 1. Initialize the Repository (which opens the DB)
	repo := database.NewRepository()
	defer func() {
		err := repo.Close()
		if err != nil {
			log.Printf("Error closing DB: %v\n", err)
		}
	}()

	// 2. Create a user struct
	user := models.User{
		ID:    "u123",
		Name:  "Alice",
		Email: "alice@example.com",
	}

	// 3. Insert the user
	docID, err := repo.InsertUser(user)
	if err != nil {
		log.Fatalf("Failed to insert user: %v", err)
	}
	fmt.Println("Inserted user with document ID:", docID)

	// 4. Retrieve the user from the DB using the docID
	fetchedUser, err := repo.GetUserByID(docID)
	if err != nil {
		log.Fatalf("Failed to fetch user by ID: %v", err)
	}

	if fetchedUser != nil {
		fmt.Printf("Fetched User: %+v\n", *fetchedUser)
	} else {
		fmt.Println("No user found with given ID")
	}
}

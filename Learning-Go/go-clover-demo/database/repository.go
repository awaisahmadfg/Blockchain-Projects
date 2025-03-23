package database

import (
	"log"

	"github.com/awaisahmadfg/go-clover-demo/models" // Update module path if needed
	"github.com/ostafen/clover"
)

const (
	dbDirectory    = "go-clover-demo" // folder for Clover DB files
	collectionName = "users"          // name of the collection
)

// Repository wraps the Clover DB instance for convenience.
type Repository struct {
	db *clover.DB
}

// NewRepository initializes and returns a new Repository.
func NewRepository() *Repository {
	// Open or create a database in the specified directory
	db, err := clover.Open(dbDirectory)
	if err != nil {
		log.Fatalf("Failed to open Clover DB: %v", err)
	}

	// Ensure the collection exists (creates if not existing)
	if !db.HasCollection(collectionName) {
		if err := db.CreateCollection(collectionName); err != nil {
			log.Fatalf("Failed to create collection: %v", err)
		}
	}

	return &Repository{db: db}
}

// InsertUser inserts a new User document into the "users" collection.
func (r *Repository) InsertUser(user models.User) (string, error) {
	// Convert the user struct to a Clover document
	doc := clover.NewDocumentFromStruct(user)

	insertedDocId, err := r.db.InsertOne(collectionName, doc)
	if err != nil {
		return "", err
	}

	return insertedDocId, nil
}

// GetUserByID retrieves a user by the Clover-generated _id field.
func (r *Repository) GetUserByID(docID string) (*models.User, error) {
	doc, err := r.db.FindById(collectionName, docID)
	if err != nil {
		return nil, err
	}
	if doc == nil {
		// No document found with given docID
		return nil, nil
	}

	// Convert Clover document back to the User struct
	var user models.User
	if err := doc.Unmarshal(&user); err != nil {
		return nil, err
	}
	return &user, nil
}

// Close closes the Clover database.
func (r *Repository) Close() error {
	return r.db.Close()
}

package models

import (
	"time"

	"github.com/google/uuid"
)

type User struct {
	ID        uuid.UUID
	GoogleID  string
	CreatedAt time.Time
}

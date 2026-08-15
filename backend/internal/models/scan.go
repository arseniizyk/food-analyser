package models

import "time"

type Scan struct {
	Barcode   string    `json:"barcode"`
	CreatedAt time.Time `json:"created_at"`
	Score     int       `json:"score"`
}

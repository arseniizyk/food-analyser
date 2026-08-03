package user

import (
	"context"
	"fmt"

	"github.com/arseniizyk/food-analyser/backend/internal/models"
)

func (s *Service) CreateIfNotExists(ctx context.Context, googleID string) (*models.User, error) {
	user, err := s.repository.CreateIfNotExists(ctx, googleID)
	if err != nil {
		return nil, fmt.Errorf("create if not exists: %w", err)
	}
	return user, nil
}

func (s *Service) AddScan(ctx context.Context, userID, barcode string) error {
	if err := s.repository.AddScan(ctx, userID, barcode); err != nil {
		return fmt.Errorf("add scan: %w", err)
	}
	return nil
}

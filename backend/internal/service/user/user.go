package user

import (
	"context"
	"errors"
	"fmt"

	"github.com/arseniizyk/food-analyser/backend/internal/errs"
	"github.com/arseniizyk/food-analyser/backend/internal/models"
)

type Repository interface {
	GetByGoogleID(ctx context.Context, googleID string) (*models.User, error)
	CreateIfNotExists(ctx context.Context, googleID string) (*models.User, error)
	AddScan(ctx context.Context, userID string, barcode string) error
	GetScans(ctx context.Context, userID string) ([]string, error)
}

type Service struct {
	repository Repository
}

func New(repository Repository) *Service {
	return &Service{repository: repository}
}

func (s *Service) GetByGoogleID(ctx context.Context, googleID string) (*models.User, error) {
	user, err := s.repository.GetByGoogleID(ctx, googleID)
	if err != nil {
		if errors.Is(err, errs.ErrUserNotFound) {
			return nil, errs.ErrUserNotFound
		}
		return nil, fmt.Errorf("get by google ID: %w", err)
	}
	return user, nil
}

func (s *Service) CreateIfNotExists(ctx context.Context, googleID string) (*models.User, error) {
	user, err := s.CreateIfNotExists(ctx, googleID)
	if err != nil {
		return nil, fmt.Errorf("create if not exists: %w", err)
	}
	return user, nil
}

func (s *Service) AddScan(ctx context.Context, userID string, barcode string) error {
	if err := s.repository.AddScan(ctx, userID, barcode); err != nil {
		return fmt.Errorf("add scan: %w", err)
	}
	return nil
}

func (s *Service) GetScans(ctx context.Context, userID string) ([]string, error) {
	scans, err := s.repository.GetScans(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("get scans: %w", err)
	}
	return scans, nil
}

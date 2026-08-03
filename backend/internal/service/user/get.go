package user

import (
	"context"
	"errors"
	"fmt"

	"github.com/arseniizyk/food-analyser/backend/internal/errs"
	"github.com/arseniizyk/food-analyser/backend/internal/models"
)

func (s *Service) GetByGoogleID(ctx context.Context, googleID string) (*models.User, error) {
	l := s.logger.With(
		"operation", "GetUserByGoogleID",
		"googleID", googleID,
	)

	user, err := s.repository.GetByGoogleID(ctx, googleID)
	if err != nil {
		if errors.Is(err, errs.ErrUserNotFound) {
			return nil, errs.ErrUserNotFound
		}

		l.Error("failed to GetUserByGoogleID", "error", err)
		return nil, fmt.Errorf("get by google ID: %w", err)
	}
	return user, nil
}

func (s *Service) GetScans(ctx context.Context, userID string) ([]string, error) {
	scans, err := s.repository.GetScans(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("get scans: %w", err)
	}
	return scans, nil
}

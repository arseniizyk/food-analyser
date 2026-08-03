package llm

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"net/http"

	"github.com/invopop/jsonschema"

	"github.com/arseniizyk/food-analyser/backend/internal/config"
	"github.com/arseniizyk/food-analyser/backend/internal/models"
)

var analysisSchema = func() any {
	r := new(jsonschema.Reflector)
	return r.Reflect(&AnalysisResponse{})
}()

type Service struct {
	cfg    *config.LLMConfig
	client *http.Client
	logger *slog.Logger
}

func New(logger *slog.Logger, cfg config.LLMConfig) *Service {
	return &Service{
		cfg:    &cfg,
		client: &http.Client{},
		logger: logger,
	}
}

func (s *Service) AnalyzeNutrition(ctx context.Context, nutrition string) (*models.Analysis, error) {
	l := s.logger.With(
		"operation", "AnalyzeNutrition",
		"nutrition_len", len(nutrition),
	)

	request := &request{
		Model: s.cfg.Model,
		Messages: []Message{
			{Role: "system", Content: systemPrompt},
			{Role: "user", Content: nutrition},
		},
		ResponseFormat: &ResponseFormat{
			Type: "json_schema",
			JSONSchema: &JSONSchema{
				Name:   "analysis",
				Strict: true,
				Schema: analysisSchema,
			},
		},
	}

	body, err := json.Marshal(request)
	if err != nil {
		l.Error("failed to marshal analysis request", "error", err)
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	var analysis *AnalysisResponse
	var lastErr error

	const maxAttempts = 5
	for attempt := 0; attempt < 5; attempt++ {
		req, err := http.NewRequestWithContext(ctx, "POST", s.cfg.URL, bytes.NewReader(body))
		if err != nil {
			l.Error("failed to create analysis request", "error", err)
			return nil, fmt.Errorf("failed to create request: %w", err)
		}

		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+s.cfg.APIKey)

		analysis, lastErr = s.doRequest(req)
		if lastErr == nil {
			l.Debug("successfully analyzed nutrition", "attempt", attempt)
			return analysisToModel(analysis), nil
		}
		l.Warn("attempt failed",
			"attempt", attempt,
			"max_attempts", maxAttempts,
			"error", lastErr,
		)
	}

	l.Error("all attempts failed to analyze nutrition", slog.Any("error", lastErr))
	return nil, fmt.Errorf("failed after %d attempts: %w", maxAttempts, lastErr)
}

func (s *Service) doRequest(req *http.Request) (*AnalysisResponse, error) {
	resp, err := s.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer func() {
		_ = resp.Body.Close()
	}()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("bad status code: %s", resp.Status)
	}

	var apiResponse response

	if err := json.NewDecoder(resp.Body).Decode(&apiResponse); err != nil {
		return nil, fmt.Errorf("failed to decode LLM api response: %w", err)
	}

	if len(apiResponse.Choices) == 0 {
		return nil, errors.New("empty choices")
	}

	var analysis AnalysisResponse

	if err := json.Unmarshal(
		[]byte(apiResponse.Choices[0].Message.Content),
		&analysis,
	); err != nil {
		return nil, fmt.Errorf("failed to decode analysis response from LLM response: %w", err)
	}

	return &analysis, nil
}

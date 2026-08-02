package llm

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"

	"github.com/arseniizyk/food-analyser/backend/internal/config"
	"github.com/arseniizyk/food-analyser/backend/internal/models"
	"github.com/invopop/jsonschema"
)

var analysisSchema = func() any {
	r := new(jsonschema.Reflector)
	return r.Reflect(&AnalysisResponse{})
}()

type Service struct {
	cfg    *config.LLMConfig
	client *http.Client
}

// TODO: add logger
func New(cfg config.LLMConfig) *Service {
	return &Service{
		cfg:    &cfg,
		client: &http.Client{},
	}
}

func (s *Service) AnalyzeNutrition(ctx context.Context, nutrition string) (*models.Analysis, error) {
	request := &request{
		Model: s.cfg.Model,
		Messages: []Message{
			{
				Role:    "system",
				Content: systemPrompt,
			},
			{
				Role:    "user",
				Content: nutrition,
			},
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
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	var analysis *AnalysisResponse

	// TODO: add logs
	for attempt := 0; attempt < 3; attempt++ {
		req, err := http.NewRequestWithContext(ctx, "POST", s.cfg.URL, bytes.NewReader(body))
		if err != nil {
			return nil, fmt.Errorf("failed to create request: %w", err)
		}

		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+s.cfg.APIKey)

		analysis, err = s.doRequest(req)
		if err == nil {
			break
		}
	}

	if analysis == nil {
		return nil, fmt.Errorf("failed after 3 attempts")
	}

	return analysisToModel(analysis), nil
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
		return nil, err
	}

	if len(apiResponse.Choices) == 0 {
		return nil, errors.New("empty choices")
	}

	var analysis AnalysisResponse

	if err := json.Unmarshal(
		[]byte(apiResponse.Choices[0].Message.Content),
		&analysis,
	); err != nil {
		return nil, err
	}

	return &analysis, nil
}

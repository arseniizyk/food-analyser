package llm

import "github.com/arseniizyk/food-analyser/backend/internal/models"

type response struct {
	Choices []struct {
		Message struct {
			Content string `json:"content"`
		} `json:"message"`
	} `json:"choices"`
}

type request struct {
	Model          string          `json:"model"`
	Messages       []Message       `json:"messages"`
	ResponseFormat *ResponseFormat `json:"response_format,omitempty"`
}

type Message struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type ResponseFormat struct {
	Type       string      `json:"type"`
	JSONSchema *JSONSchema `json:"json_schema,omitempty"`
}

type JSONSchema struct {
	Name   string `json:"name"`
	Strict bool   `json:"strict"`
	Schema any    `json:"schema"`
}

type AnalysisResponse struct {
	Score       int                  `json:"score"`
	Grade       models.GradeLevel    `json:"grade"`
	Summary     []models.SummaryItem `json:"summary"`
	Risks       []models.Risk        `json:"risks"`
	Ingredients []models.Ingredient  `json:"ingredients"`
}

func analysisToModel(resp *AnalysisResponse) *models.Analysis {
	return &models.Analysis{
		Score:       resp.Score,
		Grade:       resp.Grade,
		Summary:     resp.Summary,
		Risks:       resp.Risks,
		Ingredients: resp.Ingredients,
	}
}

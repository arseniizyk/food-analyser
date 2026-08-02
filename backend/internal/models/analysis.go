package models

import "github.com/invopop/jsonschema"

type Analysis struct {
	Barcode     string        `json:"barcode"`
	Score       int           `json:"score"`
	Grade       GradeLevel    `json:"grade"`
	Summary     []SummaryItem `json:"summary"`
	Risks       []Risk        `json:"risks"`
	Ingredients []Ingredient  `json:"ingredients"`
}

type SummaryItem struct {
	Message string `json:"message"`
}

type Ingredient struct {
	Name        string `json:"name"`
	Risk        Risk   `json:"risk"`
	Description string `json:"description"`
}

type Risk struct {
	Severity    SeverityLevel `json:"severity"`
	Title       string        `json:"title"`
	Description string        `json:"description"`
}

type GradeLevel string

const (
	GradeExcellent GradeLevel = "excellent"
	GradeGood      GradeLevel = "good"
	GradeAverage   GradeLevel = "average"
	GradePoor      GradeLevel = "poor"
)

func (GradeLevel) JSONSchema() *jsonschema.Schema {
	return &jsonschema.Schema{
		Type: "string",
		Enum: []any{
			"excellent",
			"good",
			"average",
			"poor",
		},
	}
}

type SeverityLevel string

const (
	SeverityLow    SeverityLevel = "low"
	SeverityMedium SeverityLevel = "medium"
	SeverityHigh   SeverityLevel = "high"
)

func (SeverityLevel) JSONSchema() *jsonschema.Schema {
	return &jsonschema.Schema{
		Type: "string",
		Enum: []any{
			"low",
			"medium",
			"high",
		},
	}
}

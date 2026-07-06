package models

type GradeLevel string

const (
	GradeExcellent GradeLevel = "excellent"
	GradeGood      GradeLevel = "good"
	GradeAverage   GradeLevel = "average"
	GradePoor      GradeLevel = "poor"
)

type SeverityLevel string

const (
	SeverityLow    SeverityLevel = "low"
	SeverityMedium SeverityLevel = "medium"
	SeverityHigh   SeverityLevel = "high"
)

type Analysis struct {
	Barcode     string        `json:"barcode"`
	Score       int           `json:"score"`
	Grade       GradeLevel    `json:"grade"`
	Summary     []SummaryItem `json:"summary"`
	Risks       []Risk        `json:"risks"`
	Ingredients []Ingredient  `json:"ingredients"`
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

type SummaryItem struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

type OCRResponse struct {
	Text       string  `json:"text"`
	Confidence float64 `json:"confidence"`
	Lines      []struct {
		Text       string  `json:"text"`
		Confidence float64 `json:"confidence"`
	} `json:"lines"`
}

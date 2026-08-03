package ml

type OCRResponse struct {
	Text       string  `json:"text"`
	Confidence float64 `json:"confidence"`
	Lines      []struct {
		Text       string  `json:"text"`
		Confidence float64 `json:"confidence"`
	} `json:"lines"`
}

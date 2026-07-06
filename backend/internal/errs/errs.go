package errs

import "errors"

var (
	ErrAnalysisNotFound   = errors.New("not found")
	ErrRecognizeFromImage = errors.New("recognize from image")
	ErrAnalysingNutrition = errors.New("analysing nutrition")
)

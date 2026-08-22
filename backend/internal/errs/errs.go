package errs

import "errors"

var (
	ErrAnalysisNotFound   = errors.New("not found")
	ErrUserNotFound       = errors.New("user not found")
	ErrRecognizeFromImage = errors.New("recognize from image")
	ErrAnalyzingNutrition = errors.New("analyzing nutrition")
)

type ErrorJSON struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}

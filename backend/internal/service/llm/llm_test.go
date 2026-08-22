package llm

import (
	"context"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strconv"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/arseniizyk/food-analyser/backend/internal/config"
)

const validAnalysisJSON = `{"score":80,"grade":"good","summary":["ok"],"risks":[],"ingredients":[]}`

func llmResponseBody() string {
	return `{"choices":[{"message":{"content":` + strconv.Quote(validAnalysisJSON) + `}}]}`
}

func testLogger() *slog.Logger {
	return slog.New(slog.NewTextHandler(io.Discard, nil))
}

func newTestService(url string) *Service {
	return New(testLogger(), config.LLMConfig{
		Model:   "test-model",
		URL:     url,
		APIKey:  "test-key",
		Timeout: 5 * time.Second,
	})
}

func TestAnalyzeNutrition_SuccessOnFirstAttempt(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if got := r.Header.Get("Authorization"); got != "Bearer test-key" {
			t.Errorf("Authorization header = %q, want %q", got, "Bearer test-key")
		}
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(llmResponseBody()))
	}))
	defer srv.Close()

	analysis, err := newTestService(srv.URL).AnalyzeNutrition(context.Background(), "some label text")
	if err != nil {
		t.Fatalf("AnalyzeNutrition: %v", err)
	}
	if analysis.Score != 80 {
		t.Fatalf("Score = %d, want 80", analysis.Score)
	}
	if analysis.Grade != "good" {
		t.Fatalf("Grade = %q, want good", analysis.Grade)
	}
}

func TestAnalyzeNutrition_RetriesOnServerError(t *testing.T) {
	var hits int32
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if atomic.AddInt32(&hits, 1) < 3 {
			http.Error(w, "boom", http.StatusInternalServerError)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(llmResponseBody()))
	}))
	defer srv.Close()

	analysis, err := newTestService(srv.URL).AnalyzeNutrition(context.Background(), "label")
	if err != nil {
		t.Fatalf("AnalyzeNutrition: %v", err)
	}
	if analysis.Score != 80 {
		t.Fatalf("Score = %d, want 80", analysis.Score)
	}
	if got := atomic.LoadInt32(&hits); got != 3 {
		t.Fatalf("attempts = %d, want 3", got)
	}
}

func TestAnalyzeNutrition_AllAttemptsFail(t *testing.T) {
	var hits int32
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		atomic.AddInt32(&hits, 1)
		http.Error(w, "boom", http.StatusInternalServerError)
	}))
	defer srv.Close()

	_, err := newTestService(srv.URL).AnalyzeNutrition(context.Background(), "label")
	if err == nil {
		t.Fatal("AnalyzeNutrition: expected error, got nil")
	}
	if !strings.Contains(err.Error(), "failed after 5 attempts") {
		t.Fatalf("error message = %q, want mention of 5 attempts", err)
	}
	if got := atomic.LoadInt32(&hits); got != 5 {
		t.Fatalf("attempts = %d, want 5", got)
	}
}

func TestAnalyzeNutrition_MalformedSuccessBody(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`not json`))
	}))
	defer srv.Close()

	_, err := newTestService(srv.URL).AnalyzeNutrition(context.Background(), "label")
	if err == nil {
		t.Fatal("AnalyzeNutrition: expected error, got nil")
	}
}

func TestAnalyzeNutrition_EmptyChoices(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"choices":[]}`))
	}))
	defer srv.Close()

	_, err := newTestService(srv.URL).AnalyzeNutrition(context.Background(), "label")
	if err == nil {
		t.Fatal("AnalyzeNutrition: expected error, got nil")
	}
}

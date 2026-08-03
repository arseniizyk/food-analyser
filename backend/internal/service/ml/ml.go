package ml

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"

	"github.com/arseniizyk/food-analyser/backend/internal/config"
)

type Service struct {
	client   *http.Client
	endpoint string
}

func New(ctx context.Context, cfg config.MLConfig) (*Service, error) {
	address := cfg.Address()
	baseURL := "http://" + address
	service := &Service{
		client:   &http.Client{Timeout: cfg.Timeout},
		endpoint: baseURL + "/ocr",
	}
	if err := service.ping(ctx, baseURL); err != nil {
		return nil, err
	}

	return service, nil
}

func (s *Service) GetTextFromPhoto(ctx context.Context, image io.Reader) (string, error) {
	var buf bytes.Buffer
	writer := multipart.NewWriter(&buf)

	part, err := writer.CreateFormFile("file", "image.jpg")
	if err != nil {
		return "", fmt.Errorf("create form file: %w", err)
	}

	if _, err = io.Copy(part, image); err != nil {
		return "", fmt.Errorf("copy image: %w", err)
	}

	if err := writer.Close(); err != nil {
		return "", fmt.Errorf("close writer: %w", err)
	}

	req, err := http.NewRequestWithContext(
		ctx,
		http.MethodPost,
		s.endpoint,
		&buf,
	)
	if err != nil {
		return "", fmt.Errorf("create request: %w", err)
	}

	req.Header.Set("Content-Type", writer.FormDataContentType())

	resp, err := s.client.Do(req)
	if err != nil {
		return "", fmt.Errorf("ml request failed: %w", err)
	}
	defer func() {
		_ = resp.Body.Close()
	}()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf(
			"ml error: status=%d body=%s",
			resp.StatusCode,
			string(body),
		)
	}

	var res OCRResponse
	if err := json.Unmarshal(body, &res); err != nil {
		return "", fmt.Errorf("ml decoding failed: %w", err)
	}

	return res.Text, nil
}

func (s *Service) ping(ctx context.Context, address string) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, address+"/health", http.NoBody)
	if err != nil {
		return fmt.Errorf("ping %s: %w", address, err)
	}

	resp, err := s.client.Do(req)
	if err != nil {
		return fmt.Errorf("ping %s: %w", address, err)
	}
	defer func() {
		_ = resp.Body.Close()
	}()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf(
			"unexpected status: %d %s",
			resp.StatusCode,
			resp.Status,
		)
	}

	return nil
}

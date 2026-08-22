package auth

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/arseniizyk/food-analyser/backend/internal/models"
	jwtpkg "github.com/arseniizyk/food-analyser/backend/internal/service/jwt"
)

type stubUsers struct {
	calls int
}

func (s *stubUsers) CreateIfNotExists(_ context.Context, googleID string) (*models.User, error) {
	s.calls++
	return &models.User{
		ID:        uuid.New(),
		GoogleID:  googleID,
		CreatedAt: time.Now().UTC(),
	}, nil
}

type tokenInfoResponse struct {
	Aud              string `json:"aud"`
	Sub              string `json:"sub"`
	Iss              string `json:"iss"`
	Email            string `json:"email"`
	ErrorDescription string `json:"error_description"`
}

func newTestService(t *testing.T, tokenInfoURL string, users *stubUsers) (*Service, *jwtpkg.Manager) {
	t.Helper()

	mgr, err := jwtpkg.New("test-secret", time.Hour)
	if err != nil {
		t.Fatalf("jwt.New: %v", err)
	}

	return &Service{
		clientID:       "client-id",
		iosClientID:    "ios-client-id",
		tokenInfoURL:   tokenInfoURL,
		userRepository: users,
		jwtManager:     mgr,
		httpClient:     &http.Client{Timeout: 5 * time.Second},
	}, mgr
}

func serveTokeninfo(t *testing.T, resp tokenInfoResponse, status int) *httptest.Server {
	t.Helper()

	return httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if got := r.URL.Query().Get("id_token"); got == "" {
			t.Error("missing id_token query parameter")
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(status)
		_ = json.NewEncoder(w).Encode(resp)
	}))
}

func TestAuthenticate_Success(t *testing.T) {
	srv := serveTokeninfo(t, tokenInfoResponse{
		Aud:   "client-id",
		Sub:   "google-sub-1",
		Iss:   "accounts.google.com",
		Email: "user@example.com",
	}, http.StatusOK)
	defer srv.Close()

	users := &stubUsers{}
	svc, mgr := newTestService(t, srv.URL, users)

	userID, accessToken, email, err := svc.Authenticate(context.Background(), "id-token")
	if err != nil {
		t.Fatalf("Authenticate: %v", err)
	}
	if email != "user@example.com" {
		t.Fatalf("email = %q, want user@example.com", email)
	}
	if accessToken == "" {
		t.Fatal("accessToken is empty")
	}
	parsedID, err := mgr.Parse(accessToken)
	if err != nil {
		t.Fatalf("issued token does not parse: %v", err)
	}
	if parsedID != userID {
		t.Fatalf("token subject %q != returned userID %q", parsedID, userID)
	}
	if users.calls != 1 {
		t.Fatalf("CreateIfNotExists calls = %d, want 1", users.calls)
	}
}

func TestAuthenticate_UsesIOSClientID(t *testing.T) {
	srv := serveTokeninfo(t, tokenInfoResponse{
		Aud: "ios-client-id",
		Sub: "google-sub-2",
		Iss: "https://accounts.google.com",
	}, http.StatusOK)
	defer srv.Close()

	svc, _ := newTestService(t, srv.URL, &stubUsers{})

	if _, _, _, err := svc.Authenticate(context.Background(), "id-token"); err != nil {
		t.Fatalf("Authenticate with iOS audience: %v", err)
	}
}

func TestAuthenticate_InvalidAudience(t *testing.T) {
	srv := serveTokeninfo(t, tokenInfoResponse{
		Aud: "some-other-client",
		Sub: "google-sub-3",
		Iss: "accounts.google.com",
	}, http.StatusOK)
	defer srv.Close()

	svc, _ := newTestService(t, srv.URL, &stubUsers{})

	_, _, _, err := svc.Authenticate(context.Background(), "id-token")
	if err == nil || !strings.Contains(err.Error(), "invalid audience") {
		t.Fatalf("err = %v, want invalid audience", err)
	}
}

func TestAuthenticate_InvalidIssuer(t *testing.T) {
	srv := serveTokeninfo(t, tokenInfoResponse{
		Aud: "client-id",
		Sub: "google-sub-4",
		Iss: "evil.example.com",
	}, http.StatusOK)
	defer srv.Close()

	svc, _ := newTestService(t, srv.URL, &stubUsers{})

	_, _, _, err := svc.Authenticate(context.Background(), "id-token")
	if err == nil || !strings.Contains(err.Error(), "invalid issuer") {
		t.Fatalf("err = %v, want invalid issuer", err)
	}
}

func TestAuthenticate_UpstreamErrorStatus(t *testing.T) {
	srv := serveTokeninfo(t, tokenInfoResponse{
		ErrorDescription: "invalid_token",
	}, http.StatusBadRequest)
	defer srv.Close()

	svc, _ := newTestService(t, srv.URL, &stubUsers{})

	_, _, _, err := svc.Authenticate(context.Background(), "id-token")
	if err == nil || !strings.Contains(err.Error(), "status 400") {
		t.Fatalf("err = %v, want status mention", err)
	}
}

func TestAuthenticate_UnrecognizableBody(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"unexpected": true`))
	}))
	defer srv.Close()

	svc, _ := newTestService(t, srv.URL, &stubUsers{})

	_, _, _, err := svc.Authenticate(context.Background(), "id-token")
	if err == nil || !strings.Contains(err.Error(), "decode token info") {
		t.Fatalf("err = %v, want decode error", err)
	}
}

func TestAuthenticate_EmptyIDToken(t *testing.T) {
	svc, _ := newTestService(t, "http://unused", &stubUsers{})

	if _, _, _, err := svc.Authenticate(context.Background(), ""); err == nil {
		t.Fatal("Authenticate with empty token: expected error, got nil")
	}
}

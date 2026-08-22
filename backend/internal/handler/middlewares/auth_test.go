package middlewares

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	jwtpkg "github.com/arseniizyk/food-analyser/backend/internal/service/jwt"
)

func TestJWTAuth(t *testing.T) {
	mgr, err := jwtpkg.New("test-secret", time.Hour)
	if err != nil {
		t.Fatalf("jwt.New: %v", err)
	}

	valid, err := mgr.Issue("user-1")
	if err != nil {
		t.Fatalf("Issue: %v", err)
	}

	tests := []struct {
		name       string
		path       string
		authHeader string
		wantStatus int
		wantUserID string
	}{
		{
			name:       "history with valid token",
			path:       "/api/v1/history",
			authHeader: "Bearer " + valid,
			wantStatus: http.StatusOK,
			wantUserID: "user-1",
		},
		{
			name:       "history without token is rejected",
			path:       "/api/v1/history",
			wantStatus: http.StatusUnauthorized,
		},
		{
			name:       "history with garbage token is rejected",
			path:       "/api/v1/history",
			authHeader: "Bearer not-a-jwt",
			wantStatus: http.StatusUnauthorized,
		},
		{
			name:       "history with wrong scheme is rejected",
			path:       "/api/v1/history",
			authHeader: "Token " + valid,
			wantStatus: http.StatusUnauthorized,
		},
		{
			name:       "analyze without token is allowed",
			path:       "/api/v1/analyze/460000000001",
			wantStatus: http.StatusOK,
		},
		{
			name:       "analyze with token carries user id",
			path:       "/api/v1/analyze/460000000001",
			authHeader: "Bearer " + valid,
			wantStatus: http.StatusOK,
			wantUserID: "user-1",
		},
		{
			name:       "analysis without token is allowed",
			path:       "/api/v1/analysis/460000000001",
			wantStatus: http.StatusOK,
		},
		{
			name:       "health is open",
			path:       "/api/v1/health",
			wantStatus: http.StatusOK,
		},
		{
			name:       "unknown path is open",
			path:       "/api/v1/unknown",
			wantStatus: http.StatusOK,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var gotUserID string
			handler := JWTAuth(mgr)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				if uid, ok := UserIDFromContext(r.Context()); ok {
					gotUserID = uid
				}
				w.WriteHeader(http.StatusOK)
			}))

			req := httptest.NewRequest(http.MethodGet, tt.path, http.NoBody)
			if tt.authHeader != "" {
				req.Header.Set("Authorization", tt.authHeader)
			}

			rec := httptest.NewRecorder()
			handler.ServeHTTP(rec, req)

			if rec.Code != tt.wantStatus {
				t.Fatalf("status = %d, want %d", rec.Code, tt.wantStatus)
			}
			if gotUserID != tt.wantUserID {
				t.Fatalf("user id in context = %q, want %q", gotUserID, tt.wantUserID)
			}
		})
	}
}

func TestUserIDFromContext_EmptyWhenAbsent(t *testing.T) {
	r := httptest.NewRequest(http.MethodGet, "/", http.NoBody)
	if uid, ok := UserIDFromContext(r.Context()); ok || uid != "" {
		t.Fatalf("got (%q, %v), want empty + false", uid, ok)
	}
}

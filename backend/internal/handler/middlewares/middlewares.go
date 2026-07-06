package middlewares

import (
	"log/slog"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5/middleware"
)

func RequestLogger(log *slog.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			reqID := middleware.GetReqID(r.Context())
			start := time.Now()

			l := log.With(
				"request_id", reqID,
				"path", r.URL.Path,
				"method", r.Method,
			)

			l.Info("request started")

			next.ServeHTTP(w, r)

			l.Info("request finished", "duration", time.Since(start).Seconds())
		})
	}
}

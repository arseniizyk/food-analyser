package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/arseniizyk/food-analyser/backend/internal/config"
	handler "github.com/arseniizyk/food-analyser/backend/internal/handler"
	authHandler "github.com/arseniizyk/food-analyser/backend/internal/handler/auth"
	"github.com/arseniizyk/food-analyser/backend/internal/handler/middlewares"
	productHandler "github.com/arseniizyk/food-analyser/backend/internal/handler/product"
	productRepository "github.com/arseniizyk/food-analyser/backend/internal/repository/product"
	userRepository "github.com/arseniizyk/food-analyser/backend/internal/repository/user"
	authService "github.com/arseniizyk/food-analyser/backend/internal/service/auth"
	llmService "github.com/arseniizyk/food-analyser/backend/internal/service/llm"
	mlService "github.com/arseniizyk/food-analyser/backend/internal/service/ml"
	productService "github.com/arseniizyk/food-analyser/backend/internal/service/product"
	userService "github.com/arseniizyk/food-analyser/backend/internal/service/user"
	apiv1 "github.com/arseniizyk/food-analyser/backend/pkg/openapi/backend/v1"
)

func main() {
	path := flag.String("path", "", "path to env file")
	flag.Parse()

	cfg, err := config.New(*path)
	if err != nil {
		panic(fmt.Sprintf("error building config: %v", err))
	}

	pool, err := pgxpool.New(context.Background(), cfg.Postgres.ConnString())
	if err != nil {
		panic(fmt.Sprintf("error connecting postgres: %v", err))
	}

	r := chi.NewRouter()

	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))

	r.Use(
		middleware.RequestID,
		middlewares.RequestLogger(logger),
		middleware.Recoverer,
		middleware.Timeout(cfg.HTTP.ReadTimeout),
		middleware.Compress(5),
	)

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second) // Задержка может быть больше при первом запуске ML
	defer cancel()
	mlSvc, err := mlService.New(ctx, cfg.MLConfig)
	if err != nil {
		panic(fmt.Sprintf("error connecting ml service: %v", err))
	}

	llmSvc := llmService.New(logger, cfg.LLMConfig)

	productRepo := productRepository.New(pool)
	productSvc := productService.New(productRepo, mlSvc, llmSvc)

	userRepo := userRepository.New(pool)
	userSvc := userService.New(userRepo)

	productH := productHandler.New(productSvc, userSvc)

	authSvc := authService.New(cfg.Google.ClientID, userRepo)
	authH := authHandler.New(authSvc)

	h := handler.NewHandler(authH, productH)

	apiv1.HandlerFromMux(h, r)
	server := http.Server{
		Addr:              fmt.Sprintf(":%d", cfg.HTTP.Port),
		Handler:           r,
		ReadTimeout:       cfg.HTTP.ReadTimeout,
		ReadHeaderTimeout: cfg.HTTP.ReadHeaderTimeout,
		WriteTimeout:      cfg.HTTP.WriteTimeout,
		IdleTimeout:       cfg.HTTP.IdleTimeout,
	}

	go func() {
		slog.Info("starting server", "addr", server.Addr)
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			slog.Error("error while listening server", "error", err)
		}
	}()

	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	<-sigCh
	slog.Info("shutting down...")

	ctx, cancel = context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		slog.Error("failed to shutdown server", "error", err)
	}
}

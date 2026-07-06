package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/arseniizyk/food-analyser/backend/internal/config"
	handler "github.com/arseniizyk/food-analyser/backend/internal/handler"
	authHandler "github.com/arseniizyk/food-analyser/backend/internal/handler/auth"
	productHandler "github.com/arseniizyk/food-analyser/backend/internal/handler/product"
	apiv1 "github.com/arseniizyk/food-analyser/backend/pkg/openapi/backend/v1"
	"github.com/go-chi/chi/v5"
)

func main() {
	path := flag.String("path", "", "path to env file")
	flag.Parse()

	cfg, err := config.New(*path)
	if err != nil {
		panic(fmt.Sprintf("error building config: %v", err))
	}
	r := chi.NewRouter()

	productH := productHandler.New(nil)
	authH := authHandler.New(nil)

	h := handler.NewHandler(authH, productH)

	apiv1.HandlerFromMux(h, r)
	server := http.Server{
		Addr:              net.JoinHostPort(cfg.HTTP.Host, strconv.Itoa(cfg.HTTP.Port)),
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

	sigCh := make(chan os.Signal)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	<-sigCh
	slog.Info("shutting down...")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		slog.Error("failed to shutdown server", "error", err)
	}
}

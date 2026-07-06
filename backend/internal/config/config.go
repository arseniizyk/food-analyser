package config

import (
	"fmt"
	"net"
	"strconv"
	"time"

	"github.com/ilyakaznacheev/cleanenv"
)

type Config struct {
	MLConfig  MLConfig       `env-prefix:"ML"`
	LLMConfig LLMConfig      `env-prefix:"LLM"`
	HTTP      HTTPConfig     `env-prefix:"HTTP"`
	Postgres  PostgresConfig `env-prefix:"POSTGRES"`
}

type HTTPConfig struct {
	Port              int           `env:"PORT" env-default:"8000"`
	Host              string        `env:"HOST" env-default:"localhost"`
	WriteTimeout      time.Duration `env:"WRITE_TIMEOUT" env-default:"5s"`
	ReadTimeout       time.Duration `env:"READ_TIMEOUT" env-default:"5s"`
	ReadHeaderTimeout time.Duration `env:"READ_HEADER_TIMEOUT" env-default:"5s"`
	IdleTimeout       time.Duration `env:"IDLE_TIMEOUT" env-default:"5s"`
}

type PostgresConfig struct {
	Host            string        `env:"HOST" env-default:"localhost"`
	Port            int           `env:"PORT" env-default:"5432"`
	User            string        `env:"USER" env-default:"postgres"`
	Password        string        `env:"PASSWORD" env-default:"postgres"`
	DBName          string        `env:"DB" env-default:"postgres"`
	SSLMode         string        `env:"SSLMODE" env-default:"disable"`
	MaxConns        int           `env:"MAX_CONNS" env-default:"10"`
	MinConns        int           `env:"MIN_CONNS" env-default:"2"`
	MaxConnLifetime time.Duration `env:"MAX_CONN_LIFETIME" env-default:"5m"`
	MaxConnIdleTime time.Duration `env:"MAX_CONN_IDLE_TIME" env-default:"1m"`
}

type MLConfig struct {
	Port    int           `env:"PORT" env-default:"8888"`
	Host    string        `env:"HOST" env-default:"localhost"`
	Timeout time.Duration `env:"TIMEOUT" env-default:"10s"`
}

type LLMConfig struct {
	// TODO implement LLM Service
}

func (c MLConfig) Address() string { return net.JoinHostPort(c.Host, strconv.Itoa(c.Port)) }

func (c HTTPConfig) Address() string { return net.JoinHostPort(c.Host, strconv.Itoa(c.Port)) }

func (c PostgresConfig) ConnString() string {
	return fmt.Sprintf(
		"postgres://%s:%s@%s:%d/%s?sslmode=%s&pool_max_conns=%d&pool_min_conns=%d&pool_max_conn_lifetime=%s&pool_max_conn_idle_time=%s",
		c.User,
		c.Password,
		c.Host,
		c.Port,
		c.DBName,
		c.SSLMode,
		c.MaxConns,
		c.MinConns,
		c.MaxConnLifetime,
		c.MaxConnIdleTime,
	)
}

func New(path string) (*Config, error) {
	var cfg Config
	if path != "" {
		if err := cleanenv.ReadConfig(path, &cfg); err != nil {
			return nil, fmt.Errorf("reading cfg from file: %w", err)
		}
		return &cfg, nil
	}

	if err := cleanenv.ReadEnv(&cfg); err != nil {
		return nil, fmt.Errorf("reading cfg from env: %w", err)
	}

	return &cfg, nil
}

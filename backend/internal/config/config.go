package config

import (
	"time"

	"github.com/ilyakaznacheev/cleanenv"
)

type Config struct {
	HTTP     HTTPConfig     `env-prefix:"HTTP"`
	Postgres PostgresConfig `env-prefix:"POSTGRES"`
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

func New(path string) (*Config, error) {
	var cfg Config
	if len(path) > 0 {
		if err := cleanenv.ReadConfig(path, &cfg); err != nil {
			return nil, err
		}
		return &cfg, nil
	}

	if err := cleanenv.ReadEnv(&cfg); err != nil {
		return nil, err
	}

	return &cfg, nil
}

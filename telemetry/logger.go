// SPDX-License-Identifier: TODO

package telemetry

import (
	"fmt"
	"myproject/config"
	"sync"

	"go.uber.org/zap"
)

var (
	once sync.Once
	base *zap.Logger
)

// Logger returns the shared root logger, optionally namespaced by the given names.
func Logger(names ...string) *zap.Logger {
	once.Do(func() {
		base = build()
	})

	logger := base
	for _, name := range names {
		if name == "" {
			continue
		}

		logger = logger.Named(name)
	}

	return logger
}

// Sync flushes any buffered log entries. It should be called before the process exits.
func Sync() error {
	if err := Logger().Sync(); err != nil {
		return fmt.Errorf("sync logger: %w", err)
	}

	return nil
}

// build constructs the root logger from the configuration selected by the
// DEVELOPMENT environment variable. It falls back to a no-op logger if the
// configuration cannot be built.
func build() *zap.Logger {
	var cfg zap.Config
	if config.InDevelopmentEnvironment() {
		cfg = zap.NewDevelopmentConfig()
	} else {
		cfg = zap.NewProductionConfig()
	}

	logger, err := cfg.Build()
	if err != nil {
		return zap.NewNop()
	}

	return logger
}

// SPDX-License-Identifier: TODO

// Package config holds viper configuration and default values
package config

import (
	"os"
	"runtime"
	"strconv"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

const (
	// developmentEnvVar toggles the InDevelopmentEnvironment config.
	developmentEnvVar = "DEVELOPMENT"
)

var (
	// Version is the application version. It is set from main at startup,
	// where the build injects it via -ldflags "-X main.version=...", and
	// defaults to "dev" for local builds.
	Version = "dev"
)

// InDevelopmentEnvironment reports whether the application is running in a InDevelopmentEnvironment environment.
// Set developmentEnvVar environment variable to truthy value such as "true" or "1" to enable this.
func InDevelopmentEnvironment() bool {
	value, ok := os.LookupEnv(developmentEnvVar)
	if !ok {
		return false
	}

	enabled, err := strconv.ParseBool(value)
	if err != nil {
		return false
	}

	return enabled
}

// Init configures viper: it searches for a ".<appname>.yaml" config file in
// the user's home directory, /etc/<appname> (Linux only) and the current
// directory, and enables automatic environment variable lookup. A missing
// config file is not an error.
func Init() {
	// Find home directory.
	home, err := os.UserHomeDir()
	cobra.CheckErr(err)

	// Search config in home directory with name ".config" (without extension).
	viper.AddConfigPath(home)
	if runtime.GOOS == "linux" {
		viper.AddConfigPath("/etc/" + appNameLowercase)
	}
	viper.AddConfigPath(".")
	viper.SetConfigType("yaml")
	viper.SetConfigName("." + appNameLowercase)

	viper.AutomaticEnv() // read in environment variables that match
	_ = viper.ReadInConfig()
}

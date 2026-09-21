// SPDX-License-Identifier: TODO

// Package main is the entry point of the myproject CLI. It wires the
// build-time version into the config package and hands off to the cobra
// root command.
package main

import (
	"myproject/cmd"
	"myproject/config"
)

var version = "dev"

func main() {
	config.Version = version
	cmd.Execute()
}

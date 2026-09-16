// SPDX-License-Identifier: TODO

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

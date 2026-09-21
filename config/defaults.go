// SPDX-License-Identifier: TODO

package config

import "strings"

// AppName is the human-readable application name. Its lowercase form is
// used to derive config file and directory names.
const AppName = "myproject"

var appNameLowercase = strings.ToLower(AppName)

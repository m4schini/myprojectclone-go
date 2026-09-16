#!/usr/bin/env bash
# SPDX-License-Identifier: TODO
#
# Validates a single Conventional Commits subject line, the subject is read from $1 when given, otherwise from stdin.

set -euo pipefail

# The commit types this repository accepts.
TYPES='feat|fix|chore'

# type, optional (scope), optional ! for a breaking change, ": ", description.
PATTERN="^(${TYPES})(\([a-z0-9._/-]+\))?!?: .+"

# Conventional Commits puts no limit on subject length; git's own tooling formats around 72 columns.
MAX_LEN=72

if [ $# -gt 0 ]; then
  subject="$1"
else
  IFS= read -r subject || true
fi

if [[ ! "$subject" =~ $PATTERN ]]; then
  cat >&2 <<-MSG
	error: commit subject is not a Conventional Commit:
	  $subject

	expected: <type>[(scope)][!]: <description>
	type is one of: ${TYPES//|/, }
	example: fix(config): reject an empty listen address
	MSG
  exit 1
fi

if [ "${#subject}" -gt "$MAX_LEN" ]; then
  printf 'error: commit subject is %d characters, limit is %d:\n  %s\n' \
    "${#subject}" "$MAX_LEN" "$subject" >&2
  exit 1
fi

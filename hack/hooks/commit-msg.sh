#!/usr/bin/env bash
# SPDX-License-Identifier: TODO

set -euo pipefail

VALIDATOR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/conventional-commit.sh"

if [ $# -ne 1 ] || [ ! -f "$1" ]; then
  printf 'usage: hack/hooks/commit-msg.sh COMMIT_MSG_FILE\n' >&2
  exit 2
fi

# Take the first line that is neither a comment nor blank, stopping at the
# scissors line that `git commit --verbose` uses to separate the message from
# the diff below it.
subject="$(
  awk '
    /^# ------------------------ >8 ------------------------$/ { exit }
    /^#/ { next }
    /^[[:space:]]*$/ { next }
    { print; exit }
  ' "$1"
)"

case "$subject" in
  # An empty message is git's own error to report; saying it twice helps nobody.
  '' | Merge* | Revert* | fixup!* | squash!*) exit 0 ;;
esac

"$VALIDATOR" "$subject"

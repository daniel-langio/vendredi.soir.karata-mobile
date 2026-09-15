#!/bin/sh
# Fails when a file the two Karata clients are meant to share has drifted between the repos.
#
# The web client (vendredi.soir.karata, web-ui/) and the Android client
# (vendredi.soir.karata-mobile) are two checkouts of what is really one Flutter app, with no
# tooling linking them - the histories are unrelated and code moves between them by hand, so a
# feature added to one has sat missing in the other until someone noticed. This is a stopgap
# until they become a single project with both platform folders.
#
# Usage: check-client-drift.sh <local-flutter-root> <other-flutter-root>
set -eu

local_root=$1
other_root=$2
manifest="$(dirname "$0")/shared-client-files.txt"

status=0
while IFS= read -r rel; do
  case "$rel" in '' | \#*) continue ;; esac

  mine="$local_root/$rel"
  theirs="$other_root/$rel"

  if [ ! -f "$mine" ]; then
    echo "MISSING HERE:  $mine"
    status=1
  elif [ ! -f "$theirs" ]; then
    echo "MISSING THERE: $theirs"
    status=1
  elif diff -u "$theirs" "$mine" >/dev/null 2>&1; then
    echo "in sync: $rel"
  else
    echo "DRIFTED: $rel"
    diff -u "$theirs" "$mine" || true
    status=1
  fi
done <"$manifest"

if [ "$status" -ne 0 ]; then
  echo >&2
  echo >&2 "Shared client files have drifted between the two client repos."
  echo >&2 "Copy the intended version across so both match, then push both repos."
fi

exit "$status"

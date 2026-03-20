#!/usr/bin/env bash

set -euo pipefail

flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs

if ! git diff --quiet -- lib/l10n lib/models; then
  echo "Generated sources are out of date. Please commit regenerated files."
  git diff --stat -- lib/l10n lib/models
  exit 1
fi

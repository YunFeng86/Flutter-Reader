#!/usr/bin/env bash

set -euo pipefail

dart_files=()
while IFS= read -r file; do
  dart_files+=("$file")
done < <(
  git ls-files -- \
    '*.dart' \
    ':(exclude,glob)**/*.g.dart' \
    ':(exclude,glob)**/*.freezed.dart'
)

if [[ ${#dart_files[@]} -eq 0 ]]; then
  exit 0
fi

dart format --output=none --set-exit-if-changed "${dart_files[@]}"

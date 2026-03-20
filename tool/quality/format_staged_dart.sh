#!/usr/bin/env bash

set -euo pipefail

dart_files=()

for file in "$@"; do
  if [[ ! -f "$file" ]]; then
    continue
  fi

  case "$file" in
    *.g.dart|*.freezed.dart)
      continue
      ;;
    *.dart)
      dart_files+=("$file")
      ;;
  esac
done

if [[ ${#dart_files[@]} -eq 0 ]]; then
  exit 0
fi

dart format "${dart_files[@]}"
git add -- "${dart_files[@]}"

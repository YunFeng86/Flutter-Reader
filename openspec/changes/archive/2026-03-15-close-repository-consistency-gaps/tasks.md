## 1. Canonical Facts Audit

- [x] 1.1 Inspect the current `git remote -v` output and confirm the canonical repository and issue tracker endpoints that baseline artifacts must reference.
- [x] 1.2 Search README, `pubspec.yaml`, and OpenSpec baseline specs for stale repository owners, stale issue URLs, or placeholder metadata that still drift from the canonical facts.

## 2. Baseline Consistency Updates

- [x] 2.1 Update `openspec/specs/runtime-orchestration/spec.md` to replace the archived `Purpose: TBD` placeholder with finalized descriptive text.
- [x] 2.2 Update `pubspec.yaml` metadata links so `homepage`, `repository`, and `issue_tracker` match the canonical repository endpoints confirmed in task 1.1.
- [x] 2.3 Apply any required README or baseline metadata touch-up so user-facing repository facts no longer conflict across primary artifacts.

## 3. Verification

- [x] 3.1 Re-run targeted searches for `TBD`, stale repository URLs, and mismatched issue endpoints across the affected baseline artifacts to confirm the drift is removed.
- [x] 3.2 Re-check `openspec status --change "close-repository-consistency-gaps"` and verify the change remains consistent and ready for implementation/archive flow.

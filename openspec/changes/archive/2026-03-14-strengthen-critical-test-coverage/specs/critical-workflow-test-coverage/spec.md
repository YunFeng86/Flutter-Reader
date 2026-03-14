## ADDED Requirements

### Requirement: High-risk reading workflows must have deterministic regression tests
The project MUST provide deterministic high-level tests for the reading experience so that changes to reading UI, extracted content handling, translation display, and progress restoration cannot silently regress.

#### Scenario: Reading flow covers stateful interactions
- **WHEN** a contributor changes `ReaderView` behavior related to auto-mark-read, extracted content errors, translated content rendering, search synchronization, or progress persistence
- **THEN** the test suite SHALL contain widget-level regression tests that exercise those interactions through the reader UI and fail if the behavior changes unexpectedly

### Requirement: AI orchestration must be verified as a state machine
The project MUST verify AI summary and translation behavior through provider or service-level tests that cover state transitions, cache usage, misconfiguration errors, and content invalidation.

#### Scenario: Summary and translation states remain observable
- **WHEN** article content, language settings, AI provider configuration, or cached AI artifacts change
- **THEN** automated tests SHALL verify the resulting `ArticleAiController` states, including idle, queued, running, ready, error, outdated, and language-mismatch banner behavior where applicable

### Requirement: Outbox and background sync scheduling must be protected against regressions
The project MUST verify foreground outbox flushing and background sync scheduling logic with tests that cover enablement rules, backoff behavior, successful progress, stalled progress, and no-op conditions.

#### Scenario: Sync scheduling reacts to pending work and failures
- **WHEN** account type, auto-refresh settings, outbox pending count, or flush progress changes
- **THEN** automated tests SHALL verify that outbox flush and background sync controllers compute the correct scheduling behavior, including retry backoff and disabled states

### Requirement: Background sync runner must be testable without real platform side effects
The project MUST expose a stable seam for testing `BackgroundSyncRunner` so that its refresh and outbox branches can be exercised without real platform scheduling, live network access, or production storage side effects.

#### Scenario: Runner branches can be verified with fakes
- **WHEN** tests simulate accounts, app settings, outbox contents, and sync service responses
- **THEN** the runner implementation SHALL support validating refresh gating, outbox flushing, and early-return conditions using injected or overridable dependencies

### Requirement: Critical settings workflows must be covered by interaction tests
The project MUST provide widget-level regression tests for AI service settings and subscription detail inheritance behavior, covering the flows most likely to break during UI refactors.

#### Scenario: Settings interactions preserve expected outcomes
- **WHEN** a contributor changes AI service configuration dialogs, translation provider selection, prompt reset behavior, target language selection, or subscription detail inheritance controls
- **THEN** widget tests SHALL verify the expected persisted result and visible UI state for global, category, and feed-specific settings paths

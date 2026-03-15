## ADDED Requirements

### Requirement: Application startup side effects MUST be owned by explicit runtime lifecycle boundaries
The application MUST execute startup and long-lived runtime side effects through explicit lifecycle-owned orchestration boundaries rather than directly from widget `build()` paths.

#### Scenario: Render rebuild occurs after startup
- **WHEN** theme, locale, router state, account scope, or other reactive inputs cause the app shell to rebuild after initial startup
- **THEN** notification callback registration, notification initialization, permission requests, locale bridge synchronization, and controller activation SHALL NOT re-run solely because a `build()` method executed again

#### Scenario: Runtime configuration changes after initial launch
- **WHEN** a runtime setting such as the preferred locale changes after the app has already started
- **THEN** the affected side effect SHALL be synchronized through an explicit listener or lifecycle effect instead of being embedded as an unconditional render-time action

### Requirement: Foreground and background sync paths MUST share one dependency assembly contract
The project MUST define a shared composition contract for sync-related infrastructure so foreground Riverpod providers and background sync runners construct equivalent dependencies from the same source of truth.

#### Scenario: Sync infrastructure is constructed for different execution contexts
- **WHEN** the app assembles sync-related dependencies such as HTTP clients, credential access, article caching, extraction, notifications, and sync service selection for foreground or background execution
- **THEN** both execution paths SHALL delegate to shared builders or factories instead of maintaining duplicated hand-written construction logic

#### Scenario: Shared configuration changes in the future
- **WHEN** default sync infrastructure settings such as HTTP timeouts, cache policies, notification wiring, or extractor construction are updated
- **THEN** the foreground and background sync paths SHALL observe the same defaults unless a context-specific divergence is explicitly documented and intentionally implemented

### Requirement: Best-effort runtime failures MUST remain observable
Runtime operations that are allowed to fail without aborting the primary user flow MUST still produce observable signals when they degrade unexpectedly.

#### Scenario: Non-fatal runtime side effect fails
- **WHEN** notification initialization, permission requests, locale bridge synchronization, background scheduler initialization, scheduler registration, or similar best-effort runtime work throws an unexpected exception
- **THEN** the system SHALL record contextual warning or error information instead of silently swallowing the failure

#### Scenario: Runtime capability is unavailable on the current platform
- **WHEN** a runtime feature is skipped because the platform or plugin does not support it
- **THEN** the code SHALL handle that case through an explicit unsupported-path branch or categorized exception handling rather than a generic catch-all that obscures the reason

# remote-sync-capability-policy Specification

## Purpose
Define the capability-first remote synchronization policy that distinguishes truthful deferred-sync workflows, online-required remote structure commands, and client-only local preferences for remote-backed accounts.
## Requirements
### Requirement: Remote-backed account operations MUST be classified by truthful offline capability
The system MUST classify remote-backed account operations according to whether they can provide a complete and truthful offline experience, rather than treating every action on a remote-backed account as uniformly local-first or uniformly online-only.

#### Scenario: A replayable article-state intent is triggered while offline
- **WHEN** the user marks an article read, toggles article bookmark state, or marks a supported scope as read on a remote-backed account while the remote service is unreachable
- **THEN** the system SHALL persist the local result immediately and retain a replayable intent for later remote reconciliation

#### Scenario: A remote structure command is triggered while offline
- **WHEN** the user triggers a remote-backed command that requires server-side confirmation or remote identity allocation, such as adding a remote subscription, deleting a remote subscription, moving a remote feed between categories, mutating a remote category, or triggering a remote refresh
- **THEN** the system SHALL reject the command as online-required instead of reporting a local-only structural success

### Requirement: Local-mirror reading MUST remain available without remote reachability
The system MUST continue serving remote-backed reading and browsing flows from the local mirror so already-synchronized content remains available when the remote service is unreachable.

#### Scenario: Previously synchronized content is opened while offline
- **WHEN** the user opens a previously synchronized article, feed, or category view from a remote-backed account while the remote service is unreachable
- **THEN** the application SHALL read from local persisted state and SHALL NOT require a live remote fetch to render the already-available content

### Requirement: Replayable remote-backed article intents MUST converge through deferred synchronization
The system MUST preserve replayable article-state intents as deferred-synchronization workflows that reconcile with the remote service after connectivity or remote availability returns.

#### Scenario: Deferred article intents are retried after connectivity returns
- **WHEN** the application regains the ability to contact the remote service after replayable article-state intents were queued locally
- **THEN** the system SHALL attempt remote reconciliation for those intents without requiring the user to manually repeat the original action

### Requirement: Client-only preferences MUST remain local authority
The system MUST keep client-only preferences local even when the active account is remote-backed.

#### Scenario: A client-only preference is changed on a remote-backed account
- **WHEN** the user changes a client-specific preference such as read-later state, preferred reading view, local filtering, local caching preferences, or app-specific AI/display settings
- **THEN** the system SHALL persist that preference locally and SHALL NOT require a corresponding remote structure mutation for the change to be considered successful

## MODIFIED Requirements

### Requirement: Subscription management actions MUST share one action layer across desktop and touch presenters
The application MUST let desktop menus, mobile bottom sheets, and dialog presenters trigger the same underlying feed/category management actions for rename, refresh, offline caching, move, delete, import, and export workflows, and those shared actions MUST apply the same remote/offline policy for remote-backed accounts across all presenters.

#### Scenario: A desktop and a mobile presenter expose the same remote-backed action
- **WHEN** the user triggers a feed or category management action for a remote-backed account from a desktop context menu or a touch-first bottom sheet
- **THEN** both presenters SHALL delegate to the same underlying action path so business behavior, remote/offline validation, and follow-up state changes stay consistent across form factors

#### Scenario: A new sidebar action is added in the future
- **WHEN** a contributor adds a new management action to the sidebar
- **THEN** the implementation SHALL add that behavior to the shared sidebar action layer, classify it according to the remote-sync capability policy, and let platform-specific presenters call it instead of duplicating separate behavior branches

## ADDED Requirements

### Requirement: Remote-backed subscription structure commands MUST not create false-success offline state
The application MUST treat remote-backed subscription/category structure commands as online-required whenever they cannot provide a truthful deferred-sync workflow.

#### Scenario: A remote-backed structure command is attempted without remote availability
- **WHEN** the user attempts to add a remote subscription, delete a remote subscription, move a remote feed between categories, rename or delete a remote category, or trigger a remote refresh while the remote service cannot be reached
- **THEN** the shared action layer SHALL surface an explicit online-required failure and SHALL NOT commit a local structural success that implies the remote service accepted the command

#### Scenario: A remote-backed structure command succeeds online
- **WHEN** the shared action layer successfully completes a remote-backed structure mutation or remote refresh command
- **THEN** the workflow SHALL reconcile the local mirror from the accepted remote result instead of leaving desktop and touch presenters to infer structural state independently

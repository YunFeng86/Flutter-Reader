# scene-root-composition Specification

## Purpose
TBD - created by archiving change decompose-large-scene-roots. Update Purpose after archive.
## Requirements
### Requirement: High-level scene roots MUST act as composition boundaries instead of monolithic workflow owners
The application MUST keep top-level scene roots such as `HomeScreen`, `Sidebar`, and `ReaderView` focused on dependency wiring, lifecycle hookup, layout branching, and child-scene assembly rather than accumulating unrelated workflow implementations in one widget class.

#### Scenario: A contributor adds a new non-visual workflow to a scene root
- **WHEN** a new behavior such as command orchestration, persistence logic, platform interaction, or management flow is introduced for a high-level scene
- **THEN** the implementation SHALL place that behavior in a dedicated collaborator, action layer, or child scene module instead of embedding it directly into a monolithic scene-root class

#### Scenario: A scene root is reviewed after refactor
- **WHEN** `HomeScreen`, `Sidebar`, or `ReaderView` is inspected after the decomposition change
- **THEN** rendering structure, lifecycle hookup, and delegated collaborators SHALL be distinguishable without requiring one file or state class to contain every scene workflow

### Requirement: Shared scene commands MUST be reusable across layout variants
The application MUST define shared scene commands for workflows that are available from more than one layout branch so responsive variants do not duplicate orchestration logic.

#### Scenario: The same command is triggered from different home layouts
- **WHEN** refresh, mark-all-read, next/previous article, or search navigation is triggered from desktop, tablet, or compact home layouts
- **THEN** each layout branch SHALL delegate to the same underlying home-scene command path instead of duplicating repo/service orchestration logic per branch

#### Scenario: Layout structure changes in the future
- **WHEN** a contributor adds or modifies a pane layout variant for the same destination
- **THEN** the change SHALL be able to reuse existing scene commands and shortcut bindings without re-implementing the workflow logic inside the new layout branch


## ADDED Requirements

### Requirement: UI motion MUST use a bounded shared motion baseline
The application MUST define and reuse a small shared set of motion durations, curves, and transition styles for common UI feedback so that animations remain coherent across shell, list, reader, and floating surfaces.

#### Scenario: A contributor adds or updates a UI transition
- **WHEN** a UI element such as a list item, overlay, state capsule, navigation surface, or reader control gains motion
- **THEN** the implementation SHALL use the shared motion baseline instead of inventing unrelated timing, curve, or choreography values for that component

#### Scenario: A complex transition requires coordination
- **WHEN** a transition spans multiple properties or staggered elements
- **THEN** the implementation SHALL justify explicit animation control and still map its timing to the shared motion vocabulary

### Requirement: Motion MUST reinforce state changes without delaying primary tasks
The application MUST use motion to clarify appearance, disappearance, selection, sync state, and navigation transitions without making reading, navigation, or settings interactions wait on ornamental animation.

#### Scenario: A transient status or floating control appears
- **WHEN** sync feedback, find-in-page, reader controls, or similar transient UI enters or leaves the screen
- **THEN** the animation SHALL remain brief, non-blocking, and easy to interrupt through normal user interaction

#### Scenario: List or shell content updates
- **WHEN** articles, panes, or scene-level UI change state
- **THEN** the motion SHALL emphasize continuity and orientation rather than introducing long decorative sequences that distract from reading tasks

### Requirement: Non-essential motion MUST honor platform animation-reduction preferences
The application MUST reduce or disable non-essential motion when the platform indicates that animations should be minimized.

#### Scenario: Platform requests reduced or disabled animations
- **WHEN** the active `MediaQuery` reports that animations should be disabled or reduced
- **THEN** non-essential transitions such as fades, slides, reveals, and staggered motion SHALL degrade to immediate or minimal state changes while preserving functional state feedback

#### Scenario: Essential state feedback remains necessary
- **WHEN** the UI must still communicate loading, success, or failure under reduced-motion conditions
- **THEN** the feedback SHALL use minimal visual change that preserves clarity without reintroducing full decorative animation

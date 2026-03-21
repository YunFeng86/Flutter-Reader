## ADDED Requirements

### Requirement: Reader MUST isolate major stateful behaviors into dedicated subsystems
The application MUST decompose reader-scene behaviors such as article session coordination, progress persistence and restoration, long-article chunking, search navigation, selection/context interactions, and media/dialog presentation into dedicated reader subsystems rather than mixing them inside one monolithic render class.

#### Scenario: Reader content identity changes
- **WHEN** the article id, active HTML source, translation output, or extracted-content mode changes
- **THEN** the relevant reader subsystems SHALL resynchronize through explicit handoff boundaries so progress, search state, chunk anchors, and auxiliary overlays do not rely on incidental coupling inside one giant state implementation

#### Scenario: A contributor changes one reader concern
- **WHEN** a contributor modifies reading progress, search navigation, chunked rendering, selection actions, or media presentation behavior
- **THEN** that concern SHALL be adjustable through its dedicated reader subsystem boundary without requiring unrelated reader concerns to be rewritten in the same class

### Requirement: Reader decomposition MUST preserve current reading workflow semantics
The application MUST preserve the current reader workflow semantics while refactoring internal structure so the reader remains behaviorally compatible for users and tests.

#### Scenario: A standard reading session is exercised after refactor
- **WHEN** a user opens an article, allows auto-mark-read to apply, views translated content, uses find-in-page, and reopens the article later
- **THEN** the reader SHALL continue to preserve the existing semantics for read state, translation/search synchronization, progress restoration, and reader-scene overlays

#### Scenario: Advanced reader interactions are exercised after refactor
- **WHEN** a user opens a long article, triggers chunked rendering behavior, performs desktop text selection, uses the context menu, or opens image/settings dialogs
- **THEN** the reader SHALL continue to support those advanced interactions without regressing because of the internal decomposition

## ADDED Requirements

### Requirement: Sidebar navigation rendering MUST be separated from selection and management workflows
The application MUST keep sidebar tree rendering distinct from navigation selection commands and subscription-management workflows so contributors can change the tree UI without re-embedding repo/service mutations into rendering code.

#### Scenario: A sidebar selection changes
- **WHEN** the user selects all articles, a feed, a category, or a tag from the sidebar
- **THEN** the sidebar SHALL route that interaction through explicit selection commands that update the shared selection state without requiring the tree-rendering widgets to inline the full mutation workflow

#### Scenario: Sidebar presentation is reorganized
- **WHEN** a contributor restructures sidebar sections, search filtering, or item presenters
- **THEN** the change SHALL be able to reuse the existing selection and management workflows rather than duplicating feed/category/tag mutation logic inside the new rendering structure

### Requirement: Subscription management actions MUST share one action layer across desktop and touch presenters
The application MUST let desktop menus, mobile bottom sheets, and dialog presenters trigger the same underlying feed/category management actions for rename, refresh, offline caching, move, delete, import, and export workflows.

#### Scenario: A desktop and a mobile presenter expose the same action
- **WHEN** the user triggers a feed or category management action from a desktop context menu or a touch-first bottom sheet
- **THEN** both presenters SHALL delegate to the same underlying action path so business behavior, validation, and follow-up state changes stay consistent across form factors

#### Scenario: A new sidebar action is added in the future
- **WHEN** a contributor adds a new management action to the sidebar
- **THEN** the implementation SHALL add that behavior to the shared sidebar action layer and let platform-specific presenters call it, instead of duplicating the workflow separately for desktop and mobile UI branches

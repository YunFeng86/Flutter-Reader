# reader-scene-presentation Specification

## Purpose
Define the reader-scene presentation contract that gives article reading a distinct visual identity, stable readable measure, and unobtrusive supporting controls across embedded, split-pane, and dedicated-page layouts.
## Requirements
### Requirement: Reader MUST render as a distinct themed scene
The application MUST present article reading through a dedicated reader scene with its own surface, typography, header, summary, search, and tool surface semantics rather than treating the reader as a generic detail container.

#### Scenario: An article is opened for reading
- **WHEN** the reader displays an article in embedded or dedicated-page mode
- **THEN** the title block, metadata, optional AI summary, body container, search overlay, and bottom action bar SHALL follow one reader-scene theme contract instead of inheriting unrelated list or settings styling

#### Scenario: Reader-specific chrome is updated
- **WHEN** a contributor changes reader surfaces or typography
- **THEN** those changes SHALL be applied through reader-scene theme tokens or a reader-local Theme boundary rather than scattered per-widget styling

### Requirement: Reader layout MUST preserve readable measure across pane configurations
The application MUST keep the article reading measure and supporting controls within a stable readable width and spacing model across inline panes, split panes, and dedicated reader routes.

#### Scenario: Reader is displayed in a narrow shell
- **WHEN** the available pane width falls below the threshold for comfortable side-by-side reading
- **THEN** the application SHALL move the reader to a dedicated route or layout mode that preserves readable content measure instead of compressing the reading surface indefinitely

#### Scenario: Reader is displayed in a wide shell
- **WHEN** the reader has excess horizontal space
- **THEN** the article body and reader overlays SHALL stay aligned to the configured reading measure rather than stretching to fill the entire pane width

### Requirement: Reader overlays and controls MUST support uninterrupted reading flow
The application MUST position search, summary, action, and status controls so that they remain discoverable and functional without obscuring the primary reading flow longer than necessary.

#### Scenario: Find-in-page is activated
- **WHEN** the user opens find-in-page within the reader
- **THEN** the search surface SHALL align with the reader measure, expose match navigation and close actions, and avoid permanently displacing the article content

#### Scenario: Reader actions are shown while scrolling
- **WHEN** the bottom action bar, summary card, or auxiliary reader controls are visible
- **THEN** they SHALL remain compatible with safe areas, scrolling, and text selection without blocking sustained reading interactions

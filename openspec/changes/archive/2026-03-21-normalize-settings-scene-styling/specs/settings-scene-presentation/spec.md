## ADDED Requirements

### Requirement: Settings pages MUST present a shared visual hierarchy across tabs
The application MUST render settings content through a shared settings-scene presentation contract so that section headings, grouped surfaces, action rows, value rows, form fields, and destructive actions read as one coherent product scene instead of page-local widget styling.

#### Scenario: Shared settings content is shown in different tabs
- **WHEN** a user opens app preferences, grouping and sorting, services, translation and AI services, or about
- **THEN** each tab SHALL use the same section hierarchy, grouped surface treatment, item spacing, and action emphasis model for equivalent settings content

#### Scenario: Theme inputs change
- **WHEN** theme mode, dynamic color availability, or seed preset changes
- **THEN** shared settings surfaces, rows, fields, and emphasis states SHALL update through the shared theme assembly and settings-scene primitives rather than widget-local color decisions

### Requirement: Subscription settings MUST follow the same settings-scene contract without losing management hierarchy
The application MUST present subscription global settings, category settings, and feed settings through the same settings-scene presentation contract used by other settings tabs, while preserving the category/feed/detail hierarchy and density needed for subscription management.

#### Scenario: A subscription detail page is opened
- **WHEN** a user opens global subscription settings, a category settings panel, or a feed settings panel
- **THEN** the detail content SHALL use the same section, grouped surface, field, and destructive-action patterns as the rest of the settings scene

#### Scenario: Subscription lists and trees are rendered
- **WHEN** category lists, feed lists, or subscription tree nodes are shown inside the settings scene
- **THEN** their selected, hovered, and default states SHALL derive from shared list or settings-scene styling rather than one-off container or color overrides

### Requirement: Settings layout MUST adapt across stacked and multi-pane modes without duplicating page chrome
The application MUST keep settings navigation and detail presentation visually consistent across stacked, split, and multi-pane layouts, with a single active page title, stable content spacing, and responsive action areas that remain usable at constrained widths.

#### Scenario: A stacked detail page is shown
- **WHEN** the settings scene switches from the settings list to a detail page in stacked mode
- **THEN** the UI SHALL present one active title region for the current detail context and SHALL not show duplicate page titles for the same level of navigation

#### Scenario: Horizontal space becomes constrained
- **WHEN** a settings row or toolbar contains actions that no longer fit on one line
- **THEN** the UI SHALL wrap, collapse, or otherwise responsively restack those actions while keeping all actions reachable and avoiding layout overflow

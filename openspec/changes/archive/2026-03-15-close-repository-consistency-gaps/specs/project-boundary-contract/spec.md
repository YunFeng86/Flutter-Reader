## MODIFIED Requirements

### Requirement: Baseline repository artifacts MUST be complete and non-contradictory
README, package metadata, benchmark documentation, and OpenSpec baseline artifacts MUST NOT retain placeholder metadata, contradictory statements, stale canonical repository links, or mismatched public issue endpoints after a boundary recalibration or follow-up consistency change is applied.

#### Scenario: Archived OpenSpec artifact retains a placeholder
- **WHEN** an archived or baseline OpenSpec specification still contains placeholder text such as `TBD` in required metadata fields
- **THEN** the follow-up consistency work SHALL replace that placeholder with finalized descriptive text before the change is considered complete

#### Scenario: Repository facts are stated in more than one baseline artifact
- **WHEN** the same project fact is stated across README, package metadata, benchmark descriptions, configuration comments, or OpenSpec baseline documents
- **THEN** those artifacts SHALL describe the same current reality without conflicting support claims, causes, status labels, repository owners, or issue endpoints

#### Scenario: Canonical repository endpoint differs from declared metadata
- **WHEN** the repository's canonical remote or public issue tracker differs from a link declared in package metadata or user-facing documentation
- **THEN** the change SHALL update those metadata links to the canonical endpoint and SHALL NOT leave stale repository URLs in baseline artifacts

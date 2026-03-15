# project-boundary-contract Specification

## Purpose
Define how the repository declares platform support, release readiness, optimization retention metrics, and baseline document consistency so project boundaries remain explicit and non-contradictory.
## Requirements
### Requirement: Repository MUST classify platform support using objective readiness tiers
The project MUST classify each target platform as officially supported, preview supported, or unsupported based on explicit evidence such as successful builds, verified runtime behavior, and release-readiness prerequisites rather than code presence alone.

#### Scenario: Platform lacks a release-readiness prerequisite
- **WHEN** a platform can run in development builds but still lacks a required release prerequisite such as production signing or verified packaging
- **THEN** repository-facing documentation SHALL classify that platform as preview supported or unsupported, and SHALL NOT present it as officially supported

#### Scenario: Platform is claimed as officially supported
- **WHEN** the repository marks a platform as officially supported
- **THEN** the support matrix and surrounding documentation SHALL reflect that the platform has been verified in current builds and meets the repository's declared release-readiness bar

### Requirement: Repository documentation MUST align support claims with runnable commands
User-facing setup, run, and build instructions MUST NOT imply that an unsupported platform is part of the normal supported workflow. Commands kept for experimentation or local verification MUST be explicitly labeled as preview or unsupported guidance.

#### Scenario: Unsupported or preview platform command remains documented
- **WHEN** the repository keeps a run or build command for a platform that is not officially supported
- **THEN** the command SHALL be separated from the main supported workflow or explicitly annotated so that readers cannot mistake it for a standard supported path

#### Scenario: Support table and command sections disagree
- **WHEN** a platform support matrix marks a platform as unsupported or preview supported
- **THEN** the run/build sections SHALL use the same status language and SHALL NOT contradict that classification

### Requirement: High-maintenance optimizations MUST use a single retention metric
Any benchmark that justifies continuing a high-maintenance optimization such as denormalized persisted fields MUST define one primary interpretation metric, one threshold vocabulary, and one follow-up action when measured benefit falls below the retention bar.

#### Scenario: Multiple benchmark files evaluate the same optimization
- **WHEN** the repository contains more than one benchmark or benchmark-facing explanation for the same optimization decision
- **THEN** those files SHALL describe the same primary metric, decision threshold, and interpretation bands

#### Scenario: Measured benefit is below the retention bar
- **WHEN** benchmark results fall below the documented threshold for retaining the optimization
- **THEN** the repository SHALL mark the optimization for review or follow-up work instead of silently continuing to describe it as self-justifying

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

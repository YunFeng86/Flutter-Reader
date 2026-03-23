## Context

Remote-backed accounts in Fleur currently combine multiple behavioral models. Reading is served from the local Isar mirror and cached content, article-state intents such as read/star/mark-all-read already use optimistic local updates plus outbox replay, while several subscription/category management actions still mutate local state immediately even though the remote service remains the real structural authority. This creates a mixed mental model: some actions are truthful offline, some are eventually consistent, and some appear to succeed offline even when the corresponding remote command was never accepted.

The current code also mixes two different data domains inside local feed/category records:
- remote-managed structure: subscription existence, feed-to-category placement, remote category lifecycle
- client-only preferences: filter settings, sync/cache choices, AI/display preferences, read-later and preferred reading mode

For Miniflux-backed accounts specifically, feed identity can be resolved online from remote feed lists, but categories are currently mirrored locally by name rather than by persisted remote ID. That makes article-state replay tractable, while category-structure replay remains weaker and more ambiguous.

## Goals / Non-Goals

**Goals:**
- Establish one capability-first policy for remote-backed account operations based on truthful offline capability, not just account type.
- Preserve local-mirror reading and replayable article-state intents as local-first workflows with deferred synchronization.
- Make remote structure commands explicit online-required operations when they cannot produce a truthful offline result.
- Keep client-only preferences local-only even for remote-backed accounts.
- Align subscription/category management presenters with the same policy so desktop and touch workflows behave identically.

**Non-Goals:**
- Do not implement a full offline mutation queue for remote structure commands such as add/move/delete subscription or category lifecycle changes.
- Do not redesign all local feed/category schemas or require a broad remote-ID persistence migration in this change.
- Do not change Miniflux article-sync semantics that already treat remote read/star state as authoritative.
- Do not guarantee that every remote-backed provider beyond Miniflux immediately gains identical structure-management coverage; the policy should generalize, but Miniflux is the first concrete target.

## Decisions

### 1. Classify remote-backed operations by capability, not by account type alone

The change will define four behavioral classes:
- local-mirror operations: consume already-synced local state
- local-first deferred-sync intents: truthful offline actions with stable replay semantics
- online-required commands: operations that need remote confirmation or remote identity allocation
- client-only preferences: local personalization that should never be projected onto the remote service

This policy becomes the top-level rule for deciding whether an action may succeed offline, not “is the account remote?” by itself.

Alternatives considered:
- Treat every remote-backed action as online-required.
  Rejected because article-state intents and local reading already have a truthful offline story.
- Treat every action on remote-backed accounts as local-first with later replay.
  Rejected because remote structure commands would create false-success local state and much harder conflict semantics.

### 2. Keep article-state outbox semantics limited to replayable intents

The existing outbox pattern already fits actions such as mark read, bookmark, and mark-all-read because those actions:
- have immediate truthful local meaning
- can be replayed later without requiring a new server-side identity
- converge naturally when the remote service is reachable again

This change should preserve and formalize that boundary instead of expanding outbox usage to structure commands.

Alternatives considered:
- Extend outbox to all subscription/category mutations.
  Rejected because commands like remote feed creation, deletion, move, and category lifecycle changes need stronger conflict handling, pending UX, and remote-identity guarantees than this change aims to provide.

### 3. Remote structure commands MUST require online confirmation before local structural mutation is treated as successful

For remote-backed accounts, commands such as add subscription, delete subscription, move feed to category, rename/delete remote category, and remote refresh will be treated as online-required. The action path should resolve the remote target, execute the remote command, and only then refresh or reconcile the local mirror.

If the network is unavailable or the remote command fails, the UI should report that the action requires connectivity rather than staging a local-only structural success.

Alternatives considered:
- Apply the local mutation first, then attempt remote execution later.
  Rejected because the user would observe a structure change that may never exist remotely and may later be reverted by sync.
- Disable the action entirely in remote-backed accounts.
  Rejected because the command remains valid online; the issue is offline truthfulness, not capability removal.

### 4. Client-only feed/category/article preferences remain local authority

Settings such as filter keywords, sync/cache preferences, AI-display options, read-later, and preferred reading mode are client behaviors, not remote service structure. They should stay local-only even when the active account is remote-backed.

This prevents the new policy from overreaching into personalization features that already have a complete local experience chain.

Alternatives considered:
- Mirror all feed/category settings to the remote service when possible.
  Rejected because most of these settings are app-specific and would blur the boundary between server-side subscription structure and local client behavior.

### 5. Avoid schema migration for persisted remote category/feed IDs in this change

This proposal intentionally stops short of introducing persisted remote IDs for categories/feeds. Instead, remote structure commands may resolve remote targets online from current service data:
- feed operations can resolve by remote feed URL
- category operations can resolve by current remote category title

This keeps the change focused on truthful behavior semantics rather than broad data migration. The trade-off is that category resolution remains name-based and therefore less robust than explicit remote IDs.

Alternatives considered:
- Add persisted remote IDs for feeds/categories now.
  Rejected for this change because it would expand scope into schema migration, backfill, and long-tail reconciliation work before the policy itself is established.

## Risks / Trade-offs

- [Name-based remote category resolution is weaker than persisted remote IDs] → Accept this as an explicit trade-off for the first iteration and surface clear errors when remote category lookup fails.
- [Users may perceive online-required commands as a regression from today’s local-only success illusion] → Prefer truthful failure messaging over misleading offline success; preserve offline capability where it is genuinely complete.
- [Different remote providers may support different command surfaces] → Define the policy as provider-agnostic while allowing provider-specific unsupported branches when an account type lacks a given remote command.
- [The app currently lacks a global online/offline authority service] → Treat actual command execution success/failure as the authoritative signal; avoid over-coupling UX to speculative connectivity checks.
- [Local and remote structure may already be drifted before this change lands] → Use remote refresh/reload after successful structure commands and return explicit errors when drift prevents target resolution.

## Migration Plan

1. Introduce the new capability spec that classifies operation types and defines truthful offline behavior boundaries.
2. Update the existing subscription action capability spec so shared action paths must enforce the policy consistently across desktop and touch presenters.
3. Refactor action workflows to classify each remote-backed command into local-first deferred-sync, online-required, or local-only preference behavior.
4. Keep existing outbox behavior for replayable article-state intents and explicitly prevent remote structure commands from pretending to succeed offline.
5. Add or update tests around remote-backed action semantics, especially offline failure handling for online-required commands and continued deferred-sync behavior for replayable article intents.

Rollback strategy:
- If policy-driven structure handling proves too disruptive, revert only the action-layer behavior changes and keep the new specification artifacts as the desired target state.
- Because this design avoids mandatory schema migration, rollback does not require data backfill reversal.

## Open Questions

- Should remote-backed structure actions proactively check a connectivity signal before attempting execution, or should request failure itself remain the only source of truth?
- Is explicit remote-ID persistence for categories/feeds needed in a follow-up hardening change once the policy boundary is in place?
- Should “server-triggered refresh” be exposed as a distinct remote command in the UI, or should existing refresh actions keep their current local-mirror semantics for now?

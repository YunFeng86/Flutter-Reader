## Why

Remote-backed accounts currently mix several interaction models: article state changes already behave like local-first intents with deferred remote reconciliation, while subscription/category management often mutates local state immediately even when the real source of truth is the remote service. That mismatch creates false-success offline experiences, ambiguous ownership between local preferences and remote structure, and inconsistent behavior across Miniflux-backed workflows.

## What Changes

- Define a capability-first sync policy for remote-backed accounts so each operation is classified by whether it can provide a complete, truthful offline experience.
- Preserve local-mirror reading and replayable article-state intents as local-first behaviors with deferred synchronization.
- Require remote-structure commands that need server-side confirmation or identity allocation to fail fast offline instead of creating local-only success illusions.
- Separate client-only feed/category/article preferences from remote-managed subscription structure so local personalization remains local-only.
- Align remote subscription-management actions with the chosen policy, including explicit online-required behavior for operations such as remote subscription creation, deletion, move, category mutation, and server-triggered refresh.

## Capabilities

### New Capabilities
- `remote-sync-capability-policy`: Defines how remote-backed account operations are classified into local-mirror, local-first deferred-sync, online-required, and client-only preference behaviors.

### Modified Capabilities
- `subscription-navigation-actions`: Subscription and category management actions change from implicit local mutation semantics to policy-driven remote/offline behavior with explicit online-required handling where needed.

## Impact

- Affected code: remote sync services, outbox semantics, subscription/category action workflows, add-subscription flows, and account-specific UX feedback for offline/online-required commands.
- Affected systems: Miniflux-backed account behavior first, with the same policy framework available to other remote account types such as Fever where applicable.
- Affected product semantics: some remote structure commands will no longer appear to succeed offline unless they can complete a truthful deferred-sync workflow.

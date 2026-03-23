## 1. Policy Boundaries

- [x] 1.1 Define a shared classification path for remote-backed operations so action code can distinguish local-mirror, local-first deferred-sync, online-required, and client-only preference behaviors.
- [x] 1.2 Keep replayable article-state intents on the existing outbox/deferred-sync path and prevent remote structure commands from being staged as local-first success.
- [x] 1.3 Document in code-facing comments or helper boundaries which feed/category/article settings remain client-only for remote-backed accounts.

## 2. Remote Structure Command Workflows

- [x] 2.1 Update remote-backed subscription creation to preserve explicit online-required behavior and avoid local structural mutation before remote acceptance.
- [x] 2.2 Update remote-backed feed structure commands such as delete, move, and remote refresh to execute the remote command first and reconcile the local mirror only after success.
- [x] 2.3 Update remote-backed category lifecycle commands to require remote success, resolve remote targets online, and avoid local false-success structural changes when remote execution fails.

## 3. Verification and Feedback

- [x] 3.1 Add or update tests that preserve deferred-sync semantics for replayable article-state intents on remote-backed accounts.
- [x] 3.2 Add or update tests that verify online-required remote structure commands fail without committing local structural success when the remote service is unavailable.
- [x] 3.3 Add or update user-facing feedback for online-required remote structure commands so failure states clearly indicate that connectivity or remote availability is required.

# TASK-032 implementation checklist

- [x] `1. how over the affected subsystem.` Read-only walkthrough confirmed retained flags and why the PBL02 decimal module cannot provide alphanumeric glyphs.
- [x] `2. architect for parallel design exploration.` DEC-050 closed priority and LED mapping through Architect → Reviewer.
- [x] `3. Write the throughput checkpoint as four todo items. A dimension that genuinely does not apply (single file, no fan-out) keeps its item with n/a: <reason> rather than being dropped:`
- [x] `4. Delegate code-writing to a subagent using your configured feature model (default in poteto-mode's Models section) with a specific scope (file paths, named data shape and its organizing structure per principle-model-the-domain, a state machine over scattered booleans, a table/registry over branching, a typed model over repeated shape assumptions, chosen before the delegate writes logic, and success criteria). Pick each subagent's reasoning level for the job, per the Subagents section. When the implementation admits multiple valid shapes (error handling, abstraction layer, test structure), delegate via the arena skill instead so the runners surface the alternatives and the cross-judge guards the pick. Mandatory: no skip-with-reason escape, and Laziness Protocol does not override it (the gain is review separation, not lines saved). A subagent forbidden to spawn satisfies this by owning the diff directly with the same review separation. No standing by reply that waits on a nested agent. Give every file-writing delegate its own worktree (spawn it with isolation: worktree, or hand it an exclusive branch), and do not write files or run a suite in a worktree a delegate still holds. On Claude Code, isolation: worktree branches from the remote default branch unless the worktree.baseRef setting is head. When a delegate builds on commits the default branch lacks, commit them, create its worktree with git worktree add <path> -b <delegate-branch> HEAD, and name that base commit in the brief. Fencing a file in the brief's prose is not a lock (principle-separate-before-serializing-shared-state). Comments per Comments. Surgical edits, re-ground against the source for upstream-derived files. Port shared-primitive improvements to all consumers and verify each. Commit liberally.`
- [x] `5. Verify on the matching surface. Inconclusive or wrong-surface is not a pass. Flag it.`
- [x] `6. Rebase into small, ordered commits. Stack follow-ups. Use the sequence-verifiable-units principle skill, building, verifying, and committing each small unit before the next.`
- [x] `7. If the design is contested, interrogate before shipping.`
- [x] `8. Run Opening a PR.`

## Throughput checkpoint

- Blocking first steps: DEC-050 consensus, REGRAS update and TASK-032 READY completed.
- Independent workstreams: n/a; decoder, status outputs and top share one fixed message contract.
- Shared mutable state: implementer owns `/tmp/task032-worktree`; shared workspace remains untouched until audit.
- Smallest safe decomposition: one Code Implementer owns new decoders, top, tests, QSF and explicitly allowed runners; one independent Code Auditor reviews.

## Completion notes

- `7. If the design is contested, interrogate before shipping.` skip: DEC-050 was accepted without objection; glyph patterns are fixed by the Implementation Brief.
- `8. Run Opening a PR.` skip: user requested local implementation, not PR publication.
- `6. Rebase into small, ordered commits. Stack follow-ups. Use the sequence-verifiable-units principle skill, building, verifying, and committing each small unit before the next.` skip: PBL03 base files and QSF are untracked; committing only this task would omit its existing dependencies and create a misleading partial project commit.

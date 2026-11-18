# TASK-031 implementation checklist

- [x] `1. how over the affected subsystem.` Read the video path and got a read-only trace of raster, coordinate conversion, hits, clipping and current composition.
- [x] `2. architect for parallel design exploration.` Reused the settled visual contract in DEC-044; Context Analyst confirmed that no architecture choice remains for this scope.
- [x] `3. Write the throughput checkpoint as four todo items. A dimension that genuinely does not apply (single file, no fan-out) keeps its item with n/a: <reason> rather than being dropped:`
- [x] `4. Delegate code-writing to a subagent using your configured feature model (default in poteto-mode's Models section) with a specific scope (file paths, named data shape and its organizing structure per principle-model-the-domain, a state machine over scattered booleans, a table/registry over branching, a typed model over repeated shape assumptions, chosen before the delegate writes logic, and success criteria). Pick each subagent's reasoning level for the job, per the Subagents section. When the implementation admits multiple valid shapes (error handling, abstraction layer, test structure), delegate via the arena skill instead so the runners surface the alternatives and the cross-judge guards the pick. Mandatory: no skip-with-reason escape, and Laziness Protocol does not override it (the gain is review separation, not lines saved). A subagent forbidden to spawn satisfies this by owning the diff directly with the same review separation. No standing by reply that waits on a nested agent. Give every file-writing delegate its own worktree (spawn it with isolation: worktree, or hand it an exclusive branch), and do not write files or run a suite in a worktree a delegate still holds. On Claude Code, isolation: worktree branches from the remote default branch unless the worktree.baseRef setting is head. When a delegate builds on commits the default branch lacks, commit them, create its worktree with git worktree add <path> -b <delegate-branch> HEAD, and name that base commit in the brief. Fencing a file in the brief's prose is not a lock (principle-separate-before-serializing-shared-state). Comments per Comments. Surgical edits, re-ground against the source for upstream-derived files. Port shared-primitive improvements to all consumers and verify each. Commit liberally.`
- [x] `5. Verify on the matching surface. Inconclusive or wrong-surface is not a pass. Flag it.` Independent auditor passed; video and integration runners passed again in the shared workspace after copying audited files.
- [x] `6. Rebase into small, ordered commits. Stack follow-ups. Use the sequence-verifiable-units principle skill, building, verifying, and committing each small unit before the next.` skip: PBL03 base files and QSF are untracked; a commit of only this task would omit existing dependencies and create a misleading partial project commit.
- [x] `7. If the design is contested, interrogate before shipping.` skip: DEC-044 already closed palette and priority; no contested design remains.
- [x] `8. Run Opening a PR.` skip: the user requested local implementation, not PR publication.

## Throughput checkpoint

- Blocking first steps: DEC-044 visual contract and TASK-031 READY completed before coding.
- Independent workstreams: n/a; compositor, top and pixel test share the same priority contract.
- Shared mutable state: implementer works only in `/tmp/task031-worktree`.
- Smallest safe decomposition: one implementer owns compositor/top/test changes; one independent auditor reviews the integration.

## Completion notes


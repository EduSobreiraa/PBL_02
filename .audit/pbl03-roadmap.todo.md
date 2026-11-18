# Roadmap planning checklist

- [x] When the change is one or two files with an obvious approach, skip the plan. Say so and stop.
- [x] Settle open questions by prototype before you write. Run `playbooks/prototype.md` for each. Keep the branch, the SHA, and the screenshots for Appendix A. Ask the operator only about a product or preference call that no run can settle. Give options (the **never-block-on-the-human** principle skill).
- [x] Explore in subagents with `subagent_type: "pstack:poteto-agent"` and an explicit model per the Subagents section (the **guard-the-context-window** principle skill). Pick each subagent's reasoning level for the job, per the Subagents section. Each returns file pointers, conventions, test commands, and entry points. No inlined dumps.
- [x] Copy the skeleton below into the plan file and fill every placeholder. Unless the operator names a path, write the file under the agent store (`~/.claude/orchestrate/<slug>/docs/`). Keep every heading and every sub-block in the order shown. One section per PR. One PR is one change with its own evidence (the **sequence-verifiable-units** principle skill). Name the execution playbook in **How to read this**. Pick `playbooks/autopilot-stack.md` when a PR builds on another PR, and `playbooks/autopilot-full.md` when every PR stands alone. A standing program takes `playbooks/orchestrate.md`. The execution playbook owns base selection, topology changes, and merge authority. Do not copy its rebase steps into the plan.
- [x] Write under `/technical-writing` in full, then `/unslop`. The body is one Diátaxis mode, how-to. Appendices hold explanation and reference. Each heading states the task or the finding. No long dashes. No mid-sentence colons.
- [x] Run `node skills/poteto-mode/scripts/check-plan.mjs <plan.md>` from the installed plugin and fix every line it prints (the **encode-lessons-in-structure** principle skill).
- [x] Hand back. Post the plan path and the script's output, then stop. Execution starts on the operator's explicit go, under the execution playbook the plan names.

## Skips and adaptations

- skip: Step 1 does not apply because this is a multi-stage hardware project with 14 planned implementation TASKs.
- skip: Step 2 does not settle open technical contracts. The plan records the required decision gates; no prototype can replace the documented numeric contracts or an actual timing run.
- skip: Step 3's named pstack dispatch API is unavailable in this Codex runtime. Three read-only explorers already reported requirement, architecture, and delivery findings in this session.
- skip: Step 4's PR skeleton and execution playbooks do not fit this repository's TASK workflow. Using them would invent PR ownership, merges, UI screenshots, and performance baselines. The plan instead follows `docs/agente_workflow.md` and `docs/tasks/`.
- skip: Step 6's checker is PR-specific. It reported structural errors for the missing PR sections after the plan was adapted to TASKs. Added the applicable how-to heading and corrected long dashes and mid-sentence colons; do not add fictional PR sections to satisfy it.
- skip: Step 7's explicit-go requirement does not govern documentation planning. The user directly requested that the plan be documented; implementation is not started.

---
name: agent-layer-audit
description: Classify which agentic architecture layer(s) a codebase currently implements — Reflection, Tool Use, Planning, Multi-Agent, Graph — per the loops-to-graphs progression (Ng's 4 patterns + Anthropic's 5 workflows + graph-grounded state). Reports what's present, what's missing, and whether the next layer is justified by an observed failure mode, or would be premature. Use when the user asks to audit an agent system's architecture, wants to know "what layer is this at", asks whether to add planning/multi-agent/graph to an existing agent, or references the loops-to-graphs framework by name.
---

# Agent Layer Audit

## Overview

Five layers, each externalizing something the layer below left implicit:

| Layer | Externalizes | Core mechanism |
|---|---|---|
| 1. Reflection | revision | generate → critique → revise loop, stopping rule |
| 2. Tool Use | grounding | typed tool calls, validated results |
| 3. Planning | step order | structured plan (JSON steps + deps), bounded execution |
| 4. Multi-Agent | role separation | differentiated agents, artifact-contract handoffs |
| 5. Graph | shared state | durable, versioned, provenance-tracked store multiple agents read/write |

A system can legitimately stop at any layer. The audit's job is not to recommend "add more" — it's to report what's there, whether it's done right, and whether the *next* layer would address a failure mode that's actually been observed (vs. speculative).

## Detection signals per layer

Use Grep/Explore for these. Look for the mechanism, not the exact wording — hand-rolled loops rarely say "reflection."

**Layer 1 — Reflection**
- A loop or recursive call structured as generate → evaluate/critique → revise, with a max-iteration or satisfactory-flag exit
- Separate critique step from revision step (not one "improve this" call)
- Look for: `max_iterations`, `critique`, `evaluate`, `revise`, `satisfactory`, retry loops around an LLM call with a quality check

**Layer 2 — Tool Use**
- Typed tool/function schemas passed to an LLM call (function calling, tool definitions)
- Validation of tool arguments and/or tool output before use
- Look for: tool/function schemas, `tools=[...]`, MCP server definitions, argument validation before dispatch

**Layer 3 — Planning**
- LLM produces a structured plan (steps + dependencies) *before* execution, separate from executing it
- Replan-on-failure logic that preserves already-completed steps
- Look for: plan/step data classes, dependency graphs between steps, "replan" logic, bounded step counts

**Layer 4 — Multi-Agent**
- Multiple distinct agent roles/prompts (not just one agent looping)
- Handoffs pass typed artifacts (not raw conversation history) between roles
- An orchestrator or aggregator synthesizing worker outputs
- Look for: role names (`coder`, `reviewer`, `tester`, `orchestrator`), agent framework usage (AutoGen, CrewAI, LangGraph multi-node graphs), artifact/handoff schemas

**Layer 5 — Graph**
- Persistent store multiple agents/sessions read and write (not just one process's in-memory state)
- Versioning via supersession rather than overwrite; provenance/source tracked on facts
- Queryable by any agent at any time, independent of any single conversation
- Look for: graph DB usage (Neo4j, Graphiti), entity/claim/source node types, `supersedes`/`derived_from`-style edges, any "shared memory" or "knowledge base" service agents call into

## Workflow

1. **Scope the audit.** One project, or "multiple projects" — if multiple, repeat steps 2–4 per project and report each separately; don't merge findings across projects.
2. **Explore.** Dispatch the Explore agent (or Grep directly for small repos) against the detection signals above. For each layer, come back with: present / partial / absent, plus file:line evidence.
3. **Classify severity of gaps.** For any "partial" layer, name the specific hole (e.g., "reflection loop has no iteration cap" or "multi-agent handoffs pass raw transcript, not artifacts" — these are the paper's named failure modes, reuse them).
4. **Judge next-layer justification.** For the highest layer present, check: is there a *known, observed* failure mode that the next layer up specifically addresses? If yes, name it. If the user hasn't hit that failure yet, say so plainly — don't recommend the next layer speculatively.

## Output format

One block per project:

```
### <project name>

| Layer | Status | Evidence | Gap |
|---|---|---|---|
| Reflection | present/partial/absent | file:line | — |
| Tool Use | ... | ... | ... |
| Planning | ... | ... | ... |
| Multi-Agent | ... | ... | ... |
| Graph | ... | ... | ... |

**Highest layer reached:** <layer>
**Next layer justified?** yes/no — <the specific failure mode observed, or "no failure mode reported yet — don't add it speculatively">
```

Keep it to the table plus two lines. No prose essay per project — this is meant to scan fast across several codebases.

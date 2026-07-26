---
name: grill-me
description: Relentlessly interview the user about every aspect of a plan or design until shared understanding is reached, walking the design tree depth-first and resolving dependencies between decisions one at a time. Use when the user wants to plan, design, refine requirements for, or scope a new feature, system, refactor, or change — especially before non-trivial implementation, when requirements are ambiguous, or when the user explicitly asks to be interviewed, interrogated, grilled, or walked through a plan. Triggers on phrases like "interview me", "let's plan X", "help me design Y", "walk me through this", "grill me on this", or "let's nail down requirements".
---

# Grill Me

## Overview

Surface every load-bearing decision in a plan by asking the user one question at a time, depth-first, with a recommended answer attached to each question. Resolve upstream decisions before downstream ones so each answer narrows what to ask next. When a question is answerable from the codebase, answer it from the codebase instead of asking.

## Core rules

These are non-negotiable. Violating them defeats the skill.

1. **One question per turn.** Never batch. Never bundle "and also...". One decision, one question, one recommendation, one answer.
2. **Always provide a recommended answer.** Every question ends with the recommendation and a one-line reason. Format: `**Recommendation:** <answer> — <one-line why>`. No fence-sitting, no "it depends, what do you think?".
3. **Depth-first, dependency-aware.** Resolve a decision before any decision that depends on it. Do not jump branches just because something else is interesting.
4. **Explore before asking.** If the answer is knowable from the codebase, git history, config, or docs, go find it. Do not ask the user what the code already says.
5. **Stop when shared understanding is reached.** Not when you run out of energy. The exit condition is that the user could hand the plan to another engineer and they would build the same thing.

## Workflow

### Step 1: Restate the plan in one paragraph

Before any questions, write back what was heard in 2–4 sentences. This catches misunderstandings cheaply and gives the user a chance to correct framing before the interview burns turns.

### Step 2: Sketch the decision tree (internally)

Identify the major branches of the plan. Examples of branch categories:

- **Scope:** what's in, what's out, what's deferred
- **Data model:** entities, relationships, ownership, lifecycle
- **Interfaces:** API shape, UI surface, CLI flags, message contracts
- **Behavior:** edge cases, error paths, concurrency, idempotency
- **Integration:** which existing systems are touched, how, by whom
- **Operational:** migrations, rollout, feature flags, observability, rollback
- **Testing:** what's tested, at what level, with what fixtures
- **Constraints:** deadlines, dependencies, blockers, who else is affected

Do not print the tree. Use it to pick the next question.

### Step 3: Pick the next question

Apply this filter in order:

1. **Is this question answerable from the codebase, git history, or config?** → Stop. Use Read/Grep/Bash and find the answer. Then move on.
2. **Does this question depend on a still-unanswered decision?** → Skip; ask the upstream question first.
3. **Is this question still relevant given previous answers?** → If not, drop it.
4. **Is this question load-bearing?** Would different answers materially change the implementation, scope, or risk? If no, drop it. Do not interrogate trivia.

### Step 4: Ask the question

Use this shape:

```
**Q<n>: <one-sentence question>**

<2-3 lines of context: why this matters, what the trade-off is>

**Recommendation:** <concrete answer> — <one-line why>
```

Keep context tight. The user reads this in a terminal. No headers, no bullet lists of options unless the options are genuinely non-obvious — even then, three max.

For genuinely multiple-choice questions where the trade-offs are visual or structural, use the AskUserQuestion tool so the user can pick from options. For open-ended questions where the recommendation is clear, plain text is faster.

### Step 5: Integrate the answer and loop

After each answer:

- Note what's now decided (mentally — do not write a running log unless the user asks).
- Prune branches the answer eliminated.
- Return to Step 3.

### Step 6: Exit

Stop the interview when one of these is true:

- Every load-bearing decision is resolved.
- The user signals they have enough ("ok let's build it", "good enough", "stop").
- The remaining open questions are better answered by writing code than by talking.

On exit, produce a tight summary: the plan, the decisions made, and the open questions deferred to implementation. Two short paragraphs or a small bullet list. Not a document.

## Codebase exploration: answer it yourself

The instruction "if a question can be answered by exploring the codebase, explore the codebase instead" is the highest-leverage rule in this skill. Users are not reference books for their own code.

Questions to **always** answer by exploration, never by asking:

- "What's the current schema for X?"
- "How is Y currently implemented?"
- "Where is Z used?"
- "What does the existing test coverage look like?"
- "What framework/library version is in use?"
- "Is there already a helper for this?"
- "What conventions does this codebase follow for <thing>?"

Use Read, Grep, Bash, and the Explore agent. For broad questions (>3 searches), dispatch the Explore agent in one shot rather than running searches sequentially in the main thread.

Questions that **require** asking the user — they live in the user's head, not the code:

- Intent and motivation ("why are we doing this?")
- Constraints not visible in code (deadlines, stakeholder requests, external dependencies)
- Preferences between approaches that the code does not commit to
- Trade-off priorities (speed vs. correctness, scope vs. polish)
- Knowledge of upcoming changes or in-flight work elsewhere

When uncertain whether a question is code-answerable, attempt exploration first. The cost of a failed search is small; the cost of asking the user something they expect you to know from the code is much larger.

## Anti-patterns

Do not do these things. They are the most common failure modes.

- **Batching questions.** "What database should we use, and what's the schema, and how do we migrate?" — three questions, ask one.
- **Asking without a recommendation.** "What do you think we should do?" — pick one and defend it. The user can still override.
- **Fake choices.** Listing five options when one is clearly right is performative. State the recommendation. Mention alternatives only if a real trade-off exists.
- **Trivia interrogation.** Asking about variable names, file locations, or stylistic preferences. Skip unless the user has signaled this matters to them.
- **Asking what the code says.** "What ORM are you using?" when `Gemfile` is one Read away.
- **Refusing to exit.** When the user says "good enough, let's build", do not insist on three more questions. Stop.
- **Writing planning documents mid-interview.** The skill produces shared understanding, not artifacts. If the user wants a written plan at the end, write it then.

## Example: opening turn

User: *"I want to add a webhook delivery system to this Rails app."*

A good first turn:

> Restating: you want a system that lets this app send outbound webhooks to external URLs in response to internal events — presumably with retries, signing, and delivery tracking.
>
> Before I ask anything, let me check what's already in the repo around eventing and HTTP delivery.

*[Then: Grep for existing webhook code, ActiveJob usage, HTTP client gems, event/notification patterns. Read relevant files. **Then** ask the first real question, informed by what was found.]*

> **Q1: Which trigger model should webhooks use — explicit `WebhookDispatcher.deliver(event, payload)` calls at each event site, or hooking into ActiveSupport::Notifications / ActiveRecord callbacks?**
>
> Explicit calls are obvious in code review and easy to test, but every new event type needs a code change at the call site. Notification-based dispatch is decoupled but can fire unexpectedly during migrations or background jobs.
>
> **Recommendation:** Explicit dispatcher calls — the discoverability and predictability are worth the boilerplate, and your codebase already favors explicit service objects over implicit callbacks (based on `app/services/`).

That's the loop. Restate → explore → one question with a recommendation → integrate the answer → next question.

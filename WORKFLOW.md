# Cua Learning Workflow

## Source of Truth

CURRENT.md is the source of truth for the active investigation and resume
state.

Subsystem notes contain durable detailed understanding.

Human-created diagrams contain visual mental models.

## Roles

### Human

Owns:
- architecture understanding
- state/failure reasoning
- engineering decisions
- tradeoffs
- test strategy

### ChatGPT

Teacher, architecture-reasoning partner, interviewer, and diagram reviewer.

Uses CURRENT.md to resume and produces checkpoint handoffs.

Asks for predictions.
Explains concepts.
Challenges mental models.
Validates diagrams.
Recommends targeted learning resources.

Does not maintain local files.

### Codex

Repository-aware engineering assistant.

Reads:
- Cua AGENTS.override.md
- cua-learning/CURRENT.md

Searches code.
Runs experiments.
Collects evidence.
Maintains cua-learning at checkpoints.
Later assists implementation/testing.

### Superpowers

Used through Codex when a concrete engineering workflow requires:

- systematic debugging
- design/brainstorming
- planning
- TDD
- verification
- code review

Not used as a substitute for subsystem understanding.

## Session Start

Read CURRENT.md first. Read the referenced subsystem note only when additional
detail is necessary.

Resume from Current Stopping Boundary.

Do not restart previous architecture.

## During Session

One engineering question at a time.

Human predicts.
Evidence is gathered.
Human reasons.
ChatGPT challenges.
Human explains back.

## Session End

ChatGPT produces CHECKPOINT HANDOFF.

Codex performs CHECKPOINT.

Codex updates:
- subsystem note
- CURRENT.md
- system map if appropriate
- learn-later if appropriate

Human reviews concise diff.

Commit learning workspace.

## Rule

Conversation history is disposable.

The learning workspace is durable.

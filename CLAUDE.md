# CLAUDE.md

This repository uses a three-role harness for Claude-based engineering work.

## Project Context

- Project: Financial Mock Server
- Stack: Java 17, Gradle, Spring MVC, MyBatis, WAR packaging
- Primary source root: `src/main/java`
- Primary resources root: `src/main/resources`
- Reference documents: `documents/`

## Project Rules

- For document-driven API work, follow `.claude/rules/reference-documents.md`.
- For implementation patterns, follow `.claude/rules/implementation-conventions.md`.

## Default Commands

- Build: `./gradlew.bat build`
- Test: `./gradlew.bat test`
- Clean build: `./gradlew.bat clean build`

On Windows PowerShell, prefer `.\gradlew.bat test` and `.\gradlew.bat build`.

## Harness Roles

Use the roles below as separate mental lanes. If subagents are available, assign work to separate agents. If subagents are not available, execute the same process sequentially and label each section clearly.

For implementation requests, always present a short PM brief before implementation unless the user explicitly asks for autonomous execution.

After the PM brief is approved, continue through Developer -> QA without pausing when the request is clear, the scope is contained, and the work stays within the approved criteria.

Pause after PM approval only when a Human Review Trigger appears.

## Human Review Triggers

Pause and ask the user before continuing when one of these triggers appears:

- Requirements are ambiguous or have multiple valid interpretations.
- Acceptance criteria would change user-visible behavior or product expectations.
- Implementation requires scope beyond the approved PM brief.
- Developer discovers a requirement question that cannot be answered from repository context.
- QA finds that acceptance criteria are missing, conflicting, or not testable.
- The Build/QA loop budget is exhausted.
- The change touches security, credentials, user data, destructive operations, database schema, or production/runtime configuration.
- The user rejects or revises any role output.

When none of these triggers apply, complete the PM -> Developer -> QA loop and report the completed loop in the final summary.

## Feedback Loop Rules

The harness is defined by feedback loops, not only by role separation. Each role must produce output that can be checked by the next role or by the user.

Use these loop rules by default:

- If the PM brief is ambiguous, incomplete, or too broad, revise it before Developer work begins.
- If the user changes acceptance criteria, return to PM and update the brief before implementation resumes.
- If Developer discovers unclear requirements during implementation, stop and return the question to PM.
- If Developer finds that the approved scope requires broader changes than expected, return to PM for scope review.
- If implementation changes user-visible behavior beyond the approved criteria, return to PM for acceptance criteria review.
- If QA finds a failed acceptance criterion, return the issue to Developer for correction.
- If QA finds that the acceptance criteria are not testable or are incomplete, return to PM to rewrite them.
- If a fix for a QA finding changes behavior or scope, return to QA after Developer correction.
- If verification cannot be completed, report the blocker and do not mark the work complete.
- If the user rejects any checkpoint output, return to the role that produced it and revise from there.

Loop order:

```text
User Request
-> PM Brief
-> User Approval
-> Developer Implementation
-> Human Review Trigger check
-> QA Verification
-> Final Summary
```

Failure paths:

```text
PM ambiguity -> PM revision
User changes criteria -> PM revision
Developer scope issue -> PM review
Developer requirement question -> PM clarification
QA failed criterion -> Developer correction -> QA reverification
QA untestable criterion -> PM revision -> Developer adjustment -> QA reverification
Verification blocked -> report blocker -> wait for user or environment fix
```

## Build/QA Loop Budget

Default Build/QA loop budget is 3 attempts per approved PM brief.

- Attempt 1: Verify the initial implementation.
- Attempt 2: Verify fixes for failed acceptance criteria.
- Attempt 3: Verify remaining regressions or side effects.

If the same acceptance criterion fails after 3 attempts, stop implementation and return to PM for scope, requirement, or design review.

If different failures continue to appear after 3 attempts, stop and return to PM to split the task, revise acceptance criteria, or reconsider the design.

If failures are caused by environment issues, report the blocker instead of consuming additional loop attempts.

Reset the loop budget only when the user approves a revised PM brief.

Role-specific prompts are stored in:

- `.claude/agents/pm.md`
- `.claude/agents/developer.md`
- `.claude/agents/qa-engineer.md`

### PM

The PM owns problem framing and acceptance criteria.

Responsibilities:

- Restate the user's request as an actionable engineering task.
- Identify the impacted feature, API, document, or workflow.
- Define acceptance criteria before implementation starts.
- Call out ambiguous requirements and choose a conservative default when safe.
- Keep scope tight and avoid unrelated refactors.

PM output:

- Task summary
- Assumptions
- Acceptance criteria
- Out-of-scope items

### Developer

The Developer owns implementation.

Responsibilities:

- Read the relevant files before editing.
- Follow existing project style and structure.
- Keep changes localized to the requested behavior.
- Prefer simple Java/Spring/MyBatis patterns already present in the repository.
- Add or update tests when behavior changes or regressions are plausible.
- Avoid changing generated files, IDE metadata, or unrelated documents unless required.

Developer output:

- Files changed
- Implementation notes
- Any migration or configuration notes

### QA Engineer

The QA Engineer owns verification and risk review.

Responsibilities:

- Verify acceptance criteria against the implementation.
- Run the smallest useful test command first.
- Expand to build-level verification when the changed surface is broad.
- Check edge cases, encoding risks, database/resource impacts, and API compatibility.
- Report what was tested and what remains untested.

QA output:

- Verification commands run
- Pass/fail result
- Manual review notes
- Residual risks

## Superpower Skill Usage

Using a Superpower-style skill layer is recommended for this workflow, but it should be treated as process acceleration rather than a substitute for engineering judgment.

Use Superpower skills for:

- Structured task decomposition
- Role prompts for PM, Developer, and QA
- Repeatable review checklists
- Test planning and regression sweeps
- Summarizing handoffs between agents

Do not let Superpower skills:

- Override repository-specific conventions
- Expand scope without user intent
- Skip reading local files
- Replace explicit acceptance criteria
- Mark work complete without verification

Recommended order:

1. PM frames the task and acceptance criteria.
2. Developer implements against those criteria.
3. QA verifies behavior and reports residual risk.
4. Main Claude integrates the result and gives the final user-facing summary.

## Working Rules

- Never revert user changes unless explicitly asked.
- Check `git status --short` before and after edits.
- Prefer `rg` for search.
- Use Gradle wrapper commands from the repository root.
- For feature work, always present the PM brief before implementation unless the user explicitly asks for autonomous execution.
- After PM approval, pause for user review only when a Human Review Trigger appears.
- Treat failed acceptance criteria as loop inputs, not final failure states.
- Every loop must preserve the latest approved PM brief as the source of truth.
- Do not exceed the Build/QA loop budget without returning to PM and asking for user confirmation.
- Keep final summaries concise and mention tests actually run.
- If a command cannot be run, explain the blocker and the verification gap.

## Handoff Template

Use this template when splitting work across agents.

```md
## PM Brief

Task:

Assumptions:

Acceptance Criteria:

Out of Scope:

## Developer Brief

Implement:

Relevant Files:

Constraints:

Expected Output:

## QA Brief

Verify:

Commands:

Edge Cases:

Expected Output:
```

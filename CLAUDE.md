# CLAUDE.md

This repository uses a three-role harness for Claude-based engineering work.

## Project Context

- Project: Financial Mock Server
- Stack: Java 17, Gradle, Spring MVC, MyBatis, WAR packaging
- Primary source root: `src/main/java`
- Primary resources root: `src/main/resources`
- Reference documents: `documents/`

## Default Commands

- Build: `./gradlew.bat build`
- Test: `./gradlew.bat test`
- Clean build: `./gradlew.bat clean build`

On Windows PowerShell, prefer `.\gradlew.bat test` and `.\gradlew.bat build`.

## Harness Roles

Use the roles below as separate mental lanes. If subagents are available, assign work to separate agents. If subagents are not available, execute the same process sequentially and label each section clearly.

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

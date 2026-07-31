# Reference Document Rules

Documents in `documents/` are business and API references, not automatically executable specifications.

## Use Documents As Source Of Truth For

- API names, endpoint intent, request/response field meanings, and business terminology.
- Required fields, optional fields, validation rules, and domain-specific codes.
- Expected mock scenarios, sample data patterns, and integration assumptions.
- External system contract details when they are not represented in code yet.

## Use Existing Code As Source Of Truth For

- Current package structure, naming conventions, framework patterns, and wiring.
- Existing response wrapper formats, exception handling, logging, and database access style.
- Actual behavior already covered by tests.

## When Documents And Code Conflict

1. Report the conflict in the PM brief.
2. Prefer the document for new or undocumented behavior.
3. Prefer existing code for already implemented behavior unless the user asks to align it with the document.
4. Ask the user before changing behavior that would break existing APIs, tests, or clients.

## Before Implementing Document-Driven API Work

- Identify the relevant document, workbook sheet, or section.
- Extract endpoint, request, response, validation, and sample data requirements.
- Include document-derived assumptions in the PM brief.
- If the document is ambiguous, stale, or conflicts with code, trigger user review.


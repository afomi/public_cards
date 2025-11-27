# Product Backlog

Prioritized stories linked to personas, use cases, and tests.

## Backlog Strategy

This file serves as the **source of truth** for product work. For visual project management and stakeholder visibility, consider syncing with:

- **GitHub Projects** - Native integration, automation via Actions

### Sync Options

1. **Manual** - Update both places (simple, but drift-prone)
2. **GitHub Projects as primary** - Use this file for detailed specs only
3. **Automated sync** - GitHub Action to parse this file → update Project board
4. **API-driven** - Script to generate visual board from structured data below

### Recommended Approach

Use **GitHub Projects** as the visual layer:
- Create project board with columns: Backlog | Ready | In Progress | Review | Done
- Link issues to this repo
- Reference story IDs in this file for detailed specs and traceability

---

## Story Template

```markdown
### S-[ID]: [Title]

**Priority:** [P0-Critical | P1-High | P2-Medium | P3-Low]
**Status:** [Backlog | Ready | In Progress | Review | Done]
**Points:** [Estimate]

**User Story:**
As a [persona], I want [goal] so that [benefit].

**Acceptance Criteria:**
- [ ] [Criterion 1]
- [ ] [Criterion 2]

**Links:**
- Persona: [reference]
- Use Case: [UC-ID]
- Tests: [test file path]
- PR: [link when implemented]
```

---

## Stories

<!-- Add stories below, ordered by priority -->

### Epics

| ID | Epic | Description | Stories |
|----|------|-------------|---------|
| E-1 | | | |

### Current Sprint

| ID | Story | Priority | Status | Owner |
|----|-------|----------|--------|-------|
| | | | | |

### Backlog

| ID | Story | Priority | Persona | Use Case |
|----|-------|----------|---------|----------|
| | | | | |

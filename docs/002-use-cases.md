# Use Cases

Concrete scenarios with triggers, steps, and outcomes. Each use case maps to acceptance tests.

## Template

```markdown
### UC-[ID]: [Title]

**Actor:** [Persona reference]

**Trigger:** [What initiates this use case]

**Preconditions:**
- [Required state before starting]

**Steps:**
1. [User action]
2. [System response]
3. [Continue alternating...]

**Postconditions:**
- [Expected state after completion]

**Acceptance Criteria:**
- [ ] [Testable criterion 1]
- [ ] [Testable criterion 2]

**Links:**
- Story: [backlog reference]
- Tests: [test file reference]
```

## Use Cases

### UC-01: Create a Card

**Actor:** Creator

**Trigger:** User wants to create a new public card

**Preconditions:**
- None (anonymous creation allowed initially)

**Steps:**
1. User opens the app
2. System displays card type selection (profile, project, collectible)
3. User selects card type
4. System presents card editor with type-appropriate fields
5. User fills in card content (text, images)
6. User previews card (front and back)
7. User publishes card
8. System generates unique URL and displays it

**Postconditions:**
- Card exists with unique ID and URL
- Card is publicly viewable
- Version 1 is recorded

**Acceptance Criteria:**
- [ ] User can select card type
- [ ] User can add text content to card
- [ ] User can preview both sides of card
- [ ] Published card has a unique, shareable URL
- [ ] Card renders correctly on mobile

**Links:**
- Story: S-01
- Tests: `test/acceptance/create_card_test.exs`

---

### UC-02: View a Card

**Actor:** Viewer

**Trigger:** User receives/navigates to a card URL

**Preconditions:**
- Card exists at the given URL

**Steps:**
1. User opens card URL
2. System displays card front
3. User taps/clicks to flip card
4. System displays card back
5. User can view version/ownership info

**Postconditions:**
- None (read-only)

**Acceptance Criteria:**
- [ ] Card loads and displays within 2 seconds
- [ ] Card is readable on mobile viewport
- [ ] User can flip between front and back
- [ ] Version number is visible

**Links:**
- Story: S-02
- Tests: `test/acceptance/view_card_test.exs`

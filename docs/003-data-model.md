# Data Model

Domain concepts, entities, and their relationships.

## Template

```markdown
### [Entity Name]

**Description:** [What this entity represents in the domain]

**Attributes:**
| Name | Type | Constraints | Description |
|------|------|-------------|-------------|
| id | uuid | PK | Unique identifier |
| ... | ... | ... | ... |

**Relationships:**
- belongs_to: [Parent entity]
- has_many: [Child entities]
- many_to_many: [Related entities]

**Invariants:**
- [Business rules that must always hold]
```

## Entities

<!-- Add domain entities below as the model develops -->

## Entity Relationship Diagram

```
┌─────────────┐
│             │
│   [Entity]  │
│             │
└─────────────┘
```

<!-- Update diagram as relationships are defined -->

# Plan

Current implementation plan. Updated each iteration.

## Vision

Rekindle the creative "write" culture of early web (geocities era) - when people felt comfortable expressing themselves online, before extractive social platforms.

**Core beliefs:**
- Individuals should own their data within and across distributed ecosystems
- Humans can be stronger "algorithms" and "curators" than opaque platform systems
- Open-data conventions aligned with distributed ledger principles enable this
- The technical primitives already exist - we need to foster adoption

**Public Cards** - Structured, public data objects (like vcards) extended to profiles, project scopes, trading cards. Source-of-truth objects that are versionable, ownable, and portable.

## Current Focus

## Next Steps

1. [x] Define product vision
2. [x] Draft initial personas (Creator, Viewer, Claimant)
3. [x] Write first use cases (UC-01: Create, UC-02: View)
4. [ ] Create Phoenix app
5. [ ] Implement first feature (card viewing - simplest path)

## Key Architectural Considerations

### 1. Composability & Web-Native Sharing

Cards must be **living references**, not copied snapshots. Like URLs/hyperlinks:
- A card embedded in another app should reflect the current version
- Forks/copies should know they diverged and be able to sync
- Version checking like git: compare against "main" to detect staleness

**Options to explore:**
| Approach | Pros | Cons |
|----------|------|------|
| Each card = git repo | Full version history, forks, PRs, merging | Heavy infrastructure, UX complexity |
| Card as URL + ETag/version header | Web-native, HTTP caching semantics | Limited merge capabilities |
| Card references via content-addressable hash | Immutable versions, easy diff detection | Need separate "pointer" to current |
| ActivityPub/federation model | Decentralized, updates propagate | Complexity, eventual consistency |

**Core principle:** A card URL should always return the canonical current version. Embeds/references should be able to detect when they're stale.

### 2. Web Standards Alignment

Build on existing primitives rather than inventing new ones:

| Need | Existing Standard | How We Use It |
|------|-------------------|---------------|
| Structured data | Microformats, JSON-LD, Schema.org | Cards output semantic HTML + JSON |
| Versioning | HTTP ETags, Content-Addressable Storage | Version detection for embeds |
| Embedding | oEmbed, Web Components | `<public-card>` custom element |
| Identity/Ownership | DIDs, WebFinger, IndieAuth | Claim & verify card ownership |
| Federation | ActivityPub, WebSub | Updates propagate across hosts |
| Immutability | Content-addressable hashes (IPFS, git) | Each version has permanent address |

**Philosophy:** Don't build a platform that locks people in. Build a protocol that lets people out.

### 2b. The Data Inversion Problem

**Current state:** Organizations maintain internal databases with duplicated records.
- Same person exists in 50 agency databases
- Same jurisdiction defined differently across systems
- "Authoritative" is unclear or contested
- Sync is manual, drift is constant
- This is sometimes intentional (audit trails, independence) but often accidental complexity

**Web3/DID vision:** Data is owned/managed *outside* organizational databases.
- Organizations reference a canonical external source
- Updates propagate automatically
- Provenance and authority are explicit
- Similar to how DIDs invert identity: you control it, others reference it

**The adoption friction:**
```
┌─────────────────────────────────────────────────────────────┐
│                    Adoption Barriers                         │
├─────────────────────────────────────────────────────────────┤
│ Organizational inertia    │ "We've always copied data"      │
│ Policy constraints        │ "We must maintain our own copy" │
│ Risk aversion            │ "What if the external source disappears?" │
│ Ease of use              │ "Our current workflow is simpler" │
│ Unclear utility          │ "Why change what works?"         │
└─────────────────────────────────────────────────────────────┘
```

**Path to adoption - meet people where they are:**

```
Phase 1: Export                    Phase 2: Sync                     Phase 3: Reference
─────────────────────              ─────────────────────             ─────────────────────
Org DB ──export──> Card            Org DB <──sync──> Card            Card ──reference──> Org
                                                                      (card is authoritative)
"I can publish my data             "My DB stays in sync              "I query the card,
 as a card"                         with the card"                    don't store a copy"

Low friction                       Medium friction                    High friction
Familiar mental model              Bidirectional sync                 Requires trust
No workflow change                 Some integration work              Policy changes needed
```

**Design implications for public.cards:**

1. **Export-first UX** - Make it trivially easy to create a card from existing data
   - Paste JSON, CSV import, API push
   - "Publish your database record as a card"

2. **Sync mechanisms** - Support bidirectional sync for Phase 2 adopters
   - Webhooks on card update
   - Pull-based sync endpoints
   - Conflict detection (your copy diverged from canonical)

3. **Reference reliability** - Address "what if it disappears?" fear
   - Content-addressed versions (the hash is permanent, even if host changes)
   - Multiple hosts can serve same card (federation)
   - Local cache with staleness detection

4. **Evident utility** - Show clear value immediately
   - Beautiful, shareable card view
   - Embed anywhere with one line
   - Version history without effort
   - "Your data, but better presented and more portable"

5. **Graceful degradation** - Work even if org can't fully adopt
   - Card works standalone (doesn't require org to change)
   - Can coexist with copied data (card as "canonical reference" even if copies exist)
   - Progressive enhancement toward full reference model

### 2c. DRY at the Data Layer

**Principle:** Don't Repeat Yourself - applied to data across organizations and systems.

```
Current: Scattered copies, unclear authority
──────────────────────────────────────────────────────────
   Org A DB          Org B DB          Org C DB
   ┌──────┐          ┌──────┐          ┌──────┐
   │ John │          │ John │          │ J. Smith │
   │ Smith│          │ Smith│          │        │
   │ v1.2 │          │ v1.0 │          │ v???   │
   └──────┘          └──────┘          └──────┘
   (stale)           (stale)           (diverged)

Future: Converged references, explicit authority
──────────────────────────────────────────────────────────
                    ┌─────────────────┐
                    │   Public Card   │
                    │   John Smith    │
                    │   (canonical)   │
                    │                 │
                    │ owner: did:...  │
                    │ terms: CC-BY    │
                    └─────────────────┘
                           │
          ┌────────────────┼────────────────┐
          │ sync + terms   │ sync + terms   │ sync + terms
          ▼                ▼                ▼
      Org A DB         Org B DB         Org C DB
      (reference)      (reference)      (reference)
```

**Authority model:**

| Data Type | Authority | Example |
|-----------|-----------|---------|
| Personal data | Self-sovereign individual | Your own profile card |
| Public entity | Designated steward | City clerk maintains jurisdiction card |
| Collaborative | Multi-party with governance | Open source project card |

**Terms & Usage:**
- Card owner sets terms (Creative Commons, custom license, DRM reference)
- Organizations that sync/cache must honor terms
- Terms are machine-readable, attached to card
- Audit trail: who accessed, when, under what terms

**Key insight:** Copies may still exist (for performance, offline, audit) but they:
1. Know they are copies (reference the canonical source)
2. Can detect staleness (version comparison)
3. Are subject to owner-defined terms
4. Don't claim to be authoritative

**Prototype priorities (MVP):**
1. Create card with owner identity
2. Attach terms to card
3. Embed/sync with staleness detection
4. Version history with content hashes

### 3. Architecture: Protocol + Reference Platform

```
┌─────────────────────────────────────────────────────────┐
│                   Public Cards Protocol                  │
│  (card format, versioning, embedding, ownership spec)   │
└─────────────────────────────────────────────────────────┘
            │                           │
            ▼                           ▼
┌───────────────────────┐   ┌───────────────────────┐
│    public.cards       │   │   other hosts...      │
│  (reference platform) │   │  (anyone can host)    │
└───────────────────────┘   └───────────────────────┘
            │
            │ embeds/references
            ▼
┌───────────────────────┐
│  jurisdictional.org   │
│   (first client app)  │
│   (beta test case)    │
└───────────────────────┘
```

**public.cards** = reference implementation + hosted platform
**Protocol** = spec that anyone can implement
**jurisdictional.org** = first client/consumer, tests the protocol

### 3. Jurisdictional as First Client

[jurisdictional.org](https://jurisdictional.org) provides a concrete use case with card types:
- **Jurisdiction** (city, county, state, country)
- **Agency** (department, bureau)
- **Governing Body** (council, board, commission)
- **Position** (elected/appointed role)
- **Person** (officeholder)
- **Service** (what the government provides)
- **Budget** (financial allocation)

These are public, authoritative, and have clear ownership/provenance needs - ideal for public.cards.

## Decisions Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2024-11-27 | Use GitHub Projects for visual backlog | Stakeholder visibility, native integration |
| 2024-11-27 | tldraw for wireframes | Visual, collaborative, version-controllable |
| 2024-11-27 | Cards must be references, not copies | Web-native composability, avoid stale data |
| 2024-11-27 | public.cards = protocol + reference platform | Anyone can host; we demonstrate |
| 2024-11-27 | Jurisdictional.org = first client | Beta test case for the protocol |

## Current Iteration

**Iteration:** 0 - Setup
**Goal:** Establish project foundation

### Tasks

- [x] Create docs structure
- [x] Define what we're building
- [x] Write first personas + use cases
- [x] Elaborate web standards & adoption path
- [ ] Create Phoenix app
- [ ] First passing test

---

## Iteration 1 - MVP Prototype

**Goal:** Demonstrate the core design implications with working code

### Prototype Priorities

| # | Feature | Why First |
|---|---------|-----------|
| 1 | Create card with owner identity | Foundation - cards must have authors |
| 2 | Attach terms to card | Differentiator - usage rights from day one |
| 3 | View card (HTML + JSON) | Evident utility - beautiful, shareable |
| 4 | Embed with staleness detection | Composability - the key value prop |
| 5 | Version history with content hashes | Trust - immutable audit trail |

### Acceptance Criteria

- [ ] Can create a card via web UI (paste JSON or form)
- [ ] Card has owner (email/DID for MVP)
- [ ] Card has terms (dropdown: CC-BY, CC0, All Rights Reserved)
- [ ] Card viewable at unique URL, renders nicely on mobile
- [ ] Card available as JSON-LD at same URL (content negotiation)
- [ ] Embed snippet provided (`<public-card src="...">`)
- [ ] Embed shows "updated" indicator when canonical changes
- [ ] Each save creates new version with content hash
- [ ] Can view version history

---

## Ready for Next Step

When ready, say **"let's build"** and I'll enter plan mode to design the Phoenix implementation.

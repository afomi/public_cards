# Public Cards

**Rekindling the creative web.**

Public Cards is an open protocol and reference platform for structured, public data objects - extending concepts like vcards and microformats into a composable, ownable, web-native future.

## Why

The early web was a place of creation - people built personal sites, expressed themselves, and owned their corner of the internet. Extractive social platforms replaced this with passive consumption, algorithmic feeds, and data you don't control.

Public Cards aims to:
- **Empower individuals** with ownership of their data across distributed ecosystems
- **Enable humans as curators** - stronger "algorithms" than opaque platform systems
- **Foster open-data conventions** aligned with distributed ledger principles
- **Build on web standards** that already exist, not proprietary lock-in

## What

Cards are structured, public, source-of-truth objects:

* **Profile cards** - shareable identity (create your own, or claim one created about you)
* **Project cards** - scope of work, shareable with service providers for quotes
* **Trading cards** - collectibles, game pieces, baseball cards
* **Jurisdiction cards** - governments, agencies, positions, budgets (see [jurisdictional.org](https://jurisdictional.org))

Cards are **living references**, not copied snapshots. Embed a card, and it stays current. Fork a card, and you can sync upstream changes.

## Principles

* **Web-native, mobile-first** - works everywhere, phone-optimized
* **Two-sided** - cards have front and back, like physical cards
* **Visual** - supports images, rich display
* **Versionable** - human-readable source, full history, content-addressable
* **Ownable** - claim cards about yourself, establish provenance
* **Composable** - embed, reference, fork, merge
* **Open** - protocol anyone can implement, platform that demonstrates it

## Architecture

```
┌─────────────────────────────────────┐
│       Public Cards Protocol         │
│  (format, versioning, embedding)    │
└─────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│         public.cards                │
│    (reference implementation)       │
└─────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│     Client applications             │
│  (jurisdictional.org, others...)    │
└─────────────────────────────────────┘
```

## Development

This is a Phoenix LiveView application.

```bash
# Setup
mix setup

# Start server
mix phx.server

# Visit
open http://localhost:4000
```

## Status

Early development. See `/docs` for planning artifacts.

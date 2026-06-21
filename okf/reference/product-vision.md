---
type: Vision
title: Product Vision
description: The north star for Vehicle Logbook — effortless, private peace of mind about each vehicle's cost and care — and the principles and roadmap that flow from it.
resource: https://github.com/neotamizhan/petrol_log/blob/main/docs/VISION.md
tags: [vision, product, strategy]
timestamp: 2026-06-21T00:00:00Z
---

# North Star

> Effortless peace of mind about what every vehicle costs you and what it needs next —
> kept entirely private, on your device.

The value exchange: the owner does *near-free* logging; the [system](/system.md) returns
proactive awareness — what's due, what it cost, what's coming. Every feature should either
make logging cheaper or make awareness sharper.

# Audience & Job

Conscientious owners of 1–3 vehicles who want responsible ownership without a spreadsheet.
**Not** fleet operators, OBD-II diagnostics users, or social/leaderboard seekers.

Core job: *record what happened in seconds, and trust the app to surface cost and upcoming
care without being asked.*

# Principles

1. Logging must feel free (sub-10-second, smart-defaulted).
2. The app does the thinking — surface due/next/expensive, don't make the user compute.
3. Private by default is a headline feature — the moat. See the dependency-free,
   no-analytics posture in [Dependency Inventory](/reference/dependencies.md).
4. One story per vehicle — the timeline is the product.
5. Every insight earns its place by driving a decision.

# The Three Loops

Every screen should fit one loop:

- **Capture** — record what happened. Unified into one
  [LogEntryScreen](/screens/log-entry.md) (Fuel/Service toggle, create/edit, smart defaults) —
  the first streamlining step, now shipped.
- **Attend** — what needs me. [HomeScreen](/screens/home-screen.md) as the single attention
  surface, driven by [Maintenance Due Status](/metrics/maintenance-due-status.md) and the
  [Refill Forecast](/metrics/refill-forecast.md).
- **Understand** — how cost and efficiency trend. [StatsScreen](/screens/stats-screen.md),
  curated around [Overall Stats](/metrics/overall-stats.md) and the forecast.

# Non-Goals

No OBD-II/diagnostics, no fleet management, no social, no accounts, no analytics SDKs, no ads.
Any future backup/sync must be end-to-end encrypted and opt-in.

# Roadmap (summary)

- **Now**: unify capture into one Log flow; remove the configuration tax; make Home the home.
- **Next**: value-first onboarding; curate Stats to decisions; local (offline) due/refill nudges.
- **Later**: optional E2E-encrypted backup/restore; photo capture for faster logging.

# Citations

[1] [docs/VISION.md](https://github.com/neotamizhan/petrol_log/blob/main/docs/VISION.md)

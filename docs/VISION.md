# Vehicle Logbook — Product Vision

> **Last updated:** 2026-06-21
> **Status:** Living document. The north star for product decisions; update it before the product drifts from it.

## North star

> **Effortless peace of mind about what every vehicle costs you and what it needs next — kept entirely private, on your device.**

One line to decide against:

> *Turn a few seconds of logging into always knowing your car's cost and care — privately.*

The emotional promise is **calm**. The mechanism is a tight value exchange: the owner does
*near-free* logging; the app returns *proactive awareness* — what's due, what it cost, what's
coming. Every part of the product should either **make logging cheaper** or **make the
awareness sharper**. If it does neither, it is a candidate to cut.

## Who it's for

The conscientious owner of **1–3 vehicles** who wants to be a responsible owner without
becoming a spreadsheet hobbyist.

**Not the target (deliberately):** fleet/business operators, OBD-II diagnostics enthusiasts,
and anyone wanting social/leaderboard features. Saying no to these keeps the vision unified.

## The core job

> *When I do something to my car, let me record it in seconds and trust the app to tell me —
> without my asking — what it's costing me and what it needs next.*

## Principles (the decision lens)

1. **Logging must feel free.** Sub-10-second, smart-defaulted, never "a form to fill out." Friction here is the #1 churn risk.
2. **The app does the thinking.** Surface what's due / next / expensive; never make the user compute it.
3. **Private by default is a headline feature,** not a footnote — in UX and in store copy. It is the moat.
4. **One story per vehicle.** The chronological timeline is the product; modules serve the story, not the reverse.
5. **Every insight earns its place by driving a decision.** No vanity metrics.

## The product as three loops

Every screen should fit one of these. If it doesn't, question it.

| Loop | User intent | Today | Target |
|---|---|---|---|
| **Capture** | "Record what happened" | Two flows (fuel vs service), dual-mode FAB, fuel-type & price selection each time | **One "Log" action**; type is a toggle; fields pre-filled from the vehicle and last entry |
| **Attend** | "What needs me?" | Home care panel + Maintenance screen + forecast | **Home is the single attention surface**: due/overdue + next refill + month's spend, front and center |
| **Understand** | "How are cost & efficiency trending?" | Stats screen (rich) | Keep, but curated to decisions: cost trend, cost of ownership, efficiency |

## Streamlining roadmap

### Now (highest leverage, low risk)
- **Unify capture.** Collapse the fuel and maintenance entry flows into one "Log" action with a Fuel/Service toggle; merge add/edit into single mode-aware screens. See [Unified Log Flow spec](specs/unified-log-flow.md). *This is the single biggest move toward the vision.*
- **Kill the configuration tax.** Default fuel price/currency and fuel type from the vehicle's recent history; make per-fuel-type currency an advanced option, not a gate. The median user should never open Settings to log.
- **Make Home the home.** First launch lands on Home showing this vehicle, what's due, next refill, this month's spend, and one prominent **Log** button. Demote raw list screens to secondary navigation.

### Next
- **Value-first onboarding.** Add a vehicle, log one entry, see the timeline populate — within a minute, with no Settings detour.
- **Curate Stats around the three loops.** Lead with cost trend, cost of ownership, and efficiency; everything else is progressive disclosure.
- **Local nudges (still offline).** On-device notifications for "service due" and "refill window" turn a passive ledger into a proactive co-pilot — the heart of "peace of mind."

### Later (only if they serve the vision)
- **Optional end-to-end-encrypted backup/restore** (user-held file or their own cloud). Addresses the real fear — *"what if I lose my phone?"* — without breaking the privacy promise. Any future "sync" must be E2E and opt-in, or it betrays the brand.
- **Photo capture** (receipt / odometer) to make logging a snap instead of a type.

## What this product is NOT

- **No OBD-II / live diagnostics, no fleet management, no social.** Each fractures the audience and the vision.
- **No accounts, no analytics SDKs, no ads — ever.** This privacy posture is the moat, not a limitation.
- **No feature that doesn't make logging cheaper or awareness sharper.**

## How we'd know it's working

The privacy stance means server-side instrumentation is a **deliberate non-goal** — measure by
design targets and qualitative signal, not telemetry:

- **Time-to-log** and **taps-per-entry** (design budget: <10s, ≤4 taps), measured in usability testing.
- **Entry completeness** (e.g. odometer present so efficiency works) — a design problem to solve, not a metric to harvest.
- **App Store reviews & ratings** as the primary voice of customer.
- Optionally a **local-only logging streak** the user sees — reinforces the habit without phoning home.

## Changelog

| Date | Change |
|---|---|
| 2026-06-21 | Initial product vision: north star, audience, principles, the three loops, and the streamlining roadmap. |

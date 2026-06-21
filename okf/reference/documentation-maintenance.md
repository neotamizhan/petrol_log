---
type: Reference
title: Documentation Maintenance Convention
description: The project rule that docs/ARCHITECTURE.md and this OKF bundle are kept synchronized and updated in the same commit as any significant change.
resource: https://github.com/neotamizhan/petrol_log/blob/main/CLAUDE.md
tags: [reference, process, documentation, okf]
timestamp: 2026-06-21T00:00:00Z
---

# Convention

The project maintains two synchronized knowledge artifacts, and `CLAUDE.md` requires both
to be updated **in the same commit** as any significant code change:

| Artifact | Audience | Location |
|---|---|---|
| `docs/ARCHITECTURE.md` | Humans | C4 diagrams, ERD, data flow, changelog |
| `okf/` (this bundle) | AI agents | Cross-linked concept files with YAML frontmatter |

The two must not drift apart — they describe the same [system](/system.md) from different
angles.

# What counts as a significant change

- Adding, removing, or renaming a [model](/models/index.md), field, or
  [storage key](/reference/storage-keys.md)
- Adding, removing, or renaming a [screen](/screens/index.md) or navigation route
- Adding or changing a [RecordsProvider](/state/records-provider.md) method or an
  analytics/[forecasting](/metrics/index.md) algorithm
- Adding or changing a [service](/services/index.md), storage key, or
  [migration](/reference/migrations.md)
- Adding, removing, or upgrading a [dependency](/reference/dependencies.md)
- Adding platform support or changing a [build command](/reference/platform-build-matrix.md)
- Any structural directory reorganisation

# Updating this bundle

1. Map the change to the affected concept file(s) and edit the `# Schema` / body; bump the
   `timestamp`. Add a new file for a new concept; delete and fix inbound links for a removed one.
2. Every non-reserved file needs a non-empty `type`; concrete code artifacts carry a
   `resource` GitHub blob URL, abstract concepts (metrics) omit it.
3. Use bundle-relative absolute cross-links (e.g. `/models/fuel-type.md`).
4. Regenerate indexes and validate, then append a dated entry to [log.md](/log.md):

```bash
python3 ~/.claude/skills/okf-authoring/scripts/build_index.py okf --root-version
python3 ~/.claude/skills/okf-authoring/scripts/validate_okf.py okf
```

The validator must report `CONFORMANT` with `0 error(s)` before committing.

# Citations

[1] [CLAUDE.md — Documentation Maintenance](https://github.com/neotamizhan/petrol_log/blob/main/CLAUDE.md)
[2] [AGENTS.md](https://github.com/neotamizhan/petrol_log/blob/main/AGENTS.md)

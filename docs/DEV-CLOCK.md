# PRIMMO - DEV-CLOCK

Time tracker for development phases. **Auto-updated from git commits.**

> Last updated: - | Total: **0 hours** | 0 commits

---

## Summary Statistics

| Phase | Estimated | Actual | Progress |
|-------|-----------|--------|----------|
| Design & Planning | 2.5h | 0h | ░░░░░░░░░░ 0% |
| Documentation | 1.5h | 0h | ░░░░░░░░░░ 0% |
| Building | 10h | 0h | ░░░░░░░░░░ 0% |
| Debugging | 4h | 0h | ░░░░░░░░░░ 0% |
| Testing | 2.5h | 0h | ░░░░░░░░░░ 0% |
| Shipping | 1.5h | 0h | ░░░░░░░░░░ 0% |
| **Total** | **22h** | **0h** | **0%** |

---

## Setup Instructions

### 1. Copy GitHub Action files to your project:

```
.github/
  workflows/
    dev-clock.yml
  scripts/
    update-dev-clock.js
```

### 2. Create docs/DEV-CLOCK.md (this file)

### 3. Push to GitHub - tracking starts automatically!

---

## Usage

### Normal commits (30-min buffer added automatically):
```bash
git commit -m "feat: add login screen"
```

### Explicit start time (if you started at 8am):
```bash
git commit -m "feat: add login screen [started:8am]"
```

### Session start marker:
```bash
git commit --allow-empty -m "wip: starting session [started:8am]"
```

---

## How It Works

- **Automatic tracking** from git commit timestamps
- **Session detection**: commits within 2hr gaps = same session
- **Phase detection**: parsed from commit message prefixes (feat:, fix:, docs:, etc.)
- **30-min buffer**: added before first commit of each session
- **Updates on every push** via GitHub Actions

---

## Phase Keywords

| Phase | Commit prefixes |
|-------|-----------------|
| Design & Planning | design, plan, rfc, spec, architecture |
| Documentation | docs, readme, doc: |
| Building | feat, feature, add, implement, create, build, ui, component |
| Debugging | fix, bug, hotfix, patch, debug, resolve |
| Testing | test, spec, e2e, unit, coverage |
| Shipping | deploy, release, version, publish, ci, cd |

---

**Started:** -
**Status:** Pre-Development

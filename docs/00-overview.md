# Overview

Renovate opens pull requests (merge requests on GitLab) that update dependencies. This pilot runs it **as a
container or CLI that we host ourselves**, uses only free features, and records what it takes to scan three
repos: `jyje/cluster`, `jyje/pifanctl`, `jyje/mungchilog`.

Versions used: Renovate `44.149.2` (image `ghcr.io/renovatebot/renovate`), checked on 2026-10-11.

## What is free

| Piece | Cost |
|---|---|
| Renovate itself (npm package, container image) | Free, AGPL-3.0-only |
| GitHub-hosted Actions runners | Free for public repositories. All three repos are public. |
| GitHub App for authentication | Free |
| GitLab.com CI | Free tier has a monthly compute-minute quota (see [03-gitlab.md](03-gitlab.md) for what was observed) |
| Mend Renovate hosted app | Free, but not used here: the goal is the container/CLI route |

## Ways to run it

| Mode | Used here | Notes |
|---|---|---|
| `docker run ghcr.io/renovatebot/renovate` | Yes, for dry runs on a laptop | Needs a token; `RENOVATE_DRY_RUN=full` writes nothing |
| `renovatebot/github-action` | Planned (GitHub) | Same container, driven from a workflow |
| GitLab CI job with the image | Yes (GitLab) | Plain `image:` job, no external template |
| `npx renovate` | Not needed | Docker was available |

## Two kinds of config

- **Global (self-hosted) config**: how Renovate runs (platform, token, which repos, dry run). Environment variables
  here.
- **Repository config**: `renovate.json5` in the repo (what to update, grouping, schedule).

A pitfall found while testing: putting the repository config into the global config file to simulate it behaves
differently, because `config:recommended` brings its own `ignorePaths`. See [log.md](log.md), entry 2026-10-11.

## Map of this repo

- [01-local-dry-run.md](01-local-dry-run.md): scanning with Docker, and how to read the logs
- [02-github-action.md](02-github-action.md): GitHub App + workflow
- [03-gitlab.md](03-gitlab.md): the same on gitlab.com
- [projects/](projects/): per-repo findings and recommended `renovate.json5`
- [skills-analysis.md](skills-analysis.md): which of the owner's skills apply
- [log.md](log.md): dated experiment log

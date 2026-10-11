<div align="center">

# jyje/pilot-scan-renovatebot

🤖 Scanning my own repos with self-hosted Renovate (container/CLI), GitHub Actions first, GitLab CI second

[English](README.md) / [한국어](README-ko.md)

</div>

## Overview

A pilot that records how to run [Renovate](https://docs.renovatebot.com/) from its container image, using only free
features, against three repos: `jyje/cluster`, `jyje/pifanctl` and `jyje/mungchilog`. For each repo it holds a
recommended `renovate.json5`, the evidence behind it, and the same setup on gitlab.com.

Renovate version used: `44.149.2`.

## Results

Branches Renovate wants to open, before and after the recommended config (distinct branch names from dry runs):

| Repo | No config | Recommended | Majors waiting on the dashboard |
|---|---|---|---|
| [mungchilog](docs/projects/mungchilog.md) | 42 | 24 | 13 |
| [pifanctl](docs/projects/pifanctl.md) | 4 | 2 | 1 |
| [cluster](docs/projects/cluster.md) | 117 | 1 | 1 |

What matters most per repo:

- **cluster**: `helm/**` holds vendored upstream charts (169 `values.yaml` alone). Exclude it; only the repo's own
  workflows are left.
- **pifanctl**: CI fails PRs that touch chart files without a version bump, the test Dockerfile pins the project's
  own image, and a naive config bumps Python only in CI. Three rules cover that.
- **mungchilog**: scan `dev` only (`stg`/`prd` are promoted from it), group non-major updates per app, hold majors.

## Status

| Part | State |
|---|---|
| Local container dry runs of all three repos | Done |
| Recommended configs (validated with `renovate-config-validator`) | Done |
| Workflow template (lint-clean with actionlint) | Done |
| GitLab: sandbox project, CI job on shared runners, MRs created by Renovate | Done |
| GitHub: container run on hosted runners (dry run, all three repos) | Done |
| GitHub: central workflow in this repo, config PRs in the three repos | Workflow ready; draft PRs [#112](https://github.com/jyje/mungchilog/pull/112), [#85](https://github.com/jyje/pifanctl/pull/85), [#166](https://github.com/jyje/cluster/pull/166) open; waits for `APP_PRIVATE_KEY` |

## Documents

| | |
|---|---|
| [Overview](docs/00-overview.md) | What is free, ways to run it |
| [Local dry run](docs/01-local-dry-run.md) | Docker, how to read the logs, how to test a config |
| [GitHub Actions](docs/02-github-action.md) | App, secrets, workflow, rollout order |
| [GitLab](docs/03-gitlab.md) | What worked and what did not |
| [Skills analysis](docs/skills-analysis.md) | Which of [jyje/skills](https://github.com/jyje/skills) apply |
| [Experiment log](docs/log.md) | Dated findings, including wrong guesses |

## Try it

```bash
scripts/dry-run.sh jyje/mungchilog                          # default behaviour, nothing is written
scripts/dry-run.sh jyje/mungchilog projects/mungchilog/renovate.json5
```

See [docs/01-local-dry-run.md](docs/01-local-dry-run.md) for the caveat when testing a repo config as global config.

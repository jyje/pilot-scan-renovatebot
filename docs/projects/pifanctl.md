# jyje/pifanctl

Raspberry Pi fan controller. Python application (pip requirements), Docker images, two Helm charts, released with
changesets. CI enforces a version bump.

## What Renovate sees (no config)

| Manager | Files |
|---|---|
| `pip_requirements` | `sources/requirements.{all,common,dev,mock,raspi}.txt`, all pinned with `==` |
| `dockerfile` | `docker/all.dockerfile`, `docker/raspi.dockerfile`, `tests/runtime_lab/Dockerfile` |
| `github-actions` | 4 workflows (mix of `@v7` tags and SHA pins) |
| `helm-values` | `charts/pifanctl/values.yaml`, `charts/pifanctl-operator/values.yaml` |
| `pyenv` | `.python-version` |

All five `requirements.*.txt` names are matched by the default pattern, so no `managerFilePatterns` is needed.

Candidates without config: **4 branches**.

| Update | Type |
|---|---|
| `typer 0.27.2 → 0.27.3` | patch |
| `kubernetes 36.0.3 → 37.0.1` | major |
| `matplotlib 3.10.9 → 3.11.2` | minor |
| `ghcr.io/jyje/pifanctl` digest pin in `tests/runtime_lab/Dockerfile` | digest |

The last one is noise: the test Dockerfile builds on the project's own image, so every release of pifanctl would
cause a new digest PR.

## Things specific to this repo

- **Version-bump check.** `scripts/check_version_bump.py` fails a PR that touches `sources/main.py`,
  `sources/pifanctl/` or `charts/<chart>/` (outside `ci/`) without bumping the version. Read from the script, not
  assumed: Renovate edits to `sources/requirements.*.txt`, `docker/` and workflows do **not** trigger it. Edits to
  `charts/**/values.yaml` would, and a bot cannot bump the chart version. Those are left manual.
- **Existing Dependabot** covers `pip` (`/sources`, group `python`), `docker` (`/docker`) and `github-actions`
  (group `actions`), weekly. Running both tools would open duplicate PRs. When Renovate goes live, remove the
  version-update entries from `dependabot.yaml` (security alerts are a separate setting and stay).
  Not done in this pilot, because it changes the repo's own config.
- Changesets (`.changeset/`) are for releases of the project itself; Renovate dependency PRs do not need one for
  requirements or Docker changes.

## Recommended config

[`projects/pifanctl/renovate.json5`](../../projects/pifanctl/renovate.json5)

| Setting | Reason |
|---|---|
| Common block (schedule, limits, `🤖 ci(deps):` prefix) | Same as the other repos |
| majors → dashboard approval | `kubernetes 37` waits for a tick |
| `pip_requirements` minor/patch → group `python` | Ports Dependabot's `python` group |
| `github-actions` → group `actions` | Ports Dependabot's `actions` group |
| Python version in workflows disabled | See below: a bot bumping only CI's `python-version` (3.14 → 3.15) would disagree with the Dockerfile |
| `helm-values` under `charts/**` disabled | Would always fail `check_version_bump.py` |
| `ghcr.io/jyje/pifanctl` disabled | Removes the self-referencing digest PR |

## Result

| | Branches | Majors waiting |
|---|---|---|
| No config | 4 | 0 |
| First draft of the config | 3 (`python`, `actions`, `kubernetes`) | 1 |
| Recommended config | 2 (`python`, `kubernetes`) | 1 |

So one PR (`typer` + `matplotlib`) and one dashboard checkbox (`kubernetes 37`).

The re-scan of the first draft showed that the `actions` group also contained `python-version: "3.14" → "3.15"` from
`actions/setup-python`. The Dockerfile stays on `python:3.14-slim` and `.python-version` is not touched, so CI
would diverge from the image. The "Python version is bumped by hand" rule removed it.

Small repo, small effect: the value is keeping Dependabot's grouping and avoiding three noisy or failing PRs (self
digest pin, chart values, Python bump).

## Open questions

- Actions are partly pinned by SHA (`# v7.1.1` comments) and partly by tag (`@v7`). Renovate handles both; whether
  to pin everything with `helpers:pinGitHubActionDigests` is a policy choice not made here.

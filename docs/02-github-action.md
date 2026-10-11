# GitHub Actions

> **Status: the container path is verified on GitHub-hosted runners; the real rollout is not done.**
> [`dry-run.yaml`](../templates/github/dry-run.yaml) ran green for all three repos from this repo (no secret, default
> `GITHUB_TOKEN`, `RENOVATE_DRY_RUN=full`). The GitHub App does not exist yet and nothing was committed to the
> scanned repos. Steps marked "owner" need the account owner.

## Before anything else: token scope

Files under `.github/workflows/` can only be pushed with a token that has the `workflow` scope. The `gh` login
did not have it, so the first push was rejected. The owner approved `gh auth refresh -h github.com -s workflow` in
the browser (device code), after which the push worked.

## Verification run (no App needed)

`gh workflow run dry-run.yaml -f repo=jyje/mungchilog` (also `pifanctl`, `cluster`). Results on `ubuntu-24.04`,
Renovate `44.149.2`, no repo config:

| Repo | Duration | Managers found | Branches wanted |
|---|---|---|---|
| mungchilog | 141 s | npm, dockerfile, docker-compose, github-actions, helm-values | 42 (same as the laptop run) |
| pifanctl | 62 s | as in the laptop run | |
| cluster | 1118 s (18.6 min) | as in the laptop run | |

The only warning: `Cannot access vulnerability alerts`. The default `GITHUB_TOKEN` cannot read Dependabot alerts,
which is why the App below gets "Dependabot alerts: read".

Three details of `renovatebot/github-action` that cost two failed runs:

- It forwards only `RENOVATE_*`, `LOG_LEVEL`, proxy variables and the like to the container. Anything else
  (`LOG_FILE`) must be listed in `additional-env-list`.
- It mounts nothing. A log file the container writes is lost unless a directory is mounted with `docker-volumes`.
- The container runs as a non-root user, so the host directory must be writable (`install -d -m 777`).

## Design

Per-repo workflow (option A) is the recommendation. Each repo carries `.github/workflows/renovate.yaml` and
`renovate.json5`; the run log lives next to the code it changes, and a repo can be changed or switched off without
touching the others.

| | A. Per-repo workflow | B. One central workflow in this repo |
|---|---|---|
| Config location | `renovate.json5` in each repo | global config here, no repo config (or presets) |
| Logs | in each repo | all in one place |
| Secrets | App id + key in each repo | once, here |
| Adding a repo | add two files | add a name to a list |
| Weak point | three copies of the workflow | repo-specific rules are awkward without repo config |

B is not built; this repo only keeps the dry-run script for it.

## Steps

1. **(owner) Create a GitHub App** under *Settings > Developer settings > GitHub Apps*, not public, no webhook.
   Repository permissions: Contents (R/W), Pull requests (R/W), Issues (R/W, for the Dependency Dashboard),
   Workflows (R/W, to edit files under `.github/workflows`), Checks (R/W), Commit statuses (R/W),
   Dependabot alerts (R), Metadata (R). Install it on `jyje/cluster`, `jyje/pifanctl`, `jyje/mungchilog` only.
2. **(owner) Add two repository secrets** to each repo: `RENOVATE_APP_ID` and `RENOVATE_APP_PRIVATE_KEY` (the PEM
   downloaded in step 1). Put the key in via `gh secret set RENOVATE_APP_PRIVATE_KEY < key.pem` or the web UI.
   It should not be pasted into chat or committed.
3. Commit `templates/github/renovate.yaml` to `.github/workflows/` and the repo's file from `projects/<repo>/` to
   the repo root as `renovate.json5`. Do it by pull request, not by direct push.
4. Run the workflow by hand (`workflow_dispatch`, dry run `full`). Read the log for the same managers and branches
   as in the local dry runs ([projects/](projects/)).
5. Switch the dry run off (`dry-run: off`) once, check the first PRs and that their CI runs, then leave the
   Sunday-night schedule on.
6. Remove the overlapping Dependabot *version update* entries in `cluster` (`github-actions`) and `pifanctl`
   (`pip`, `docker`, `github-actions`) in a separate PR. Keep Dependabot security alerts.

Order of rollout: `mungchilog` (simplest, no Dependabot to remove) → `pifanctl` → `cluster`.

## Why a GitHub App and not `GITHUB_TOKEN`

Pushes and PRs made with `GITHUB_TOKEN` do not trigger other workflows, so Renovate PRs would sit without CI. An
App token does. A fine-grained PAT would also work but is tied to the owner's account and expires.

## Workflow template notes

[`templates/github/renovate.yaml`](../templates/github/renovate.yaml)

- Actions are pinned by commit SHA with the version in a comment: `actions/checkout` v7.0.1,
  `actions/create-github-app-token` v3.2.0, `renovatebot/github-action` v46.3.7. `actionlint` finds no problem.
- `renovate-version: 44.149.2` pins the Renovate image the action uses.
- Manual runs default to a dry run; scheduled runs create PRs.
- `RENOVATE_REQUIRE_CONFIG: required` and `RENOVATE_ONBOARDING: false`: the config is committed on purpose, no
  onboarding PR.
- The cron is Sunday 20:00 UTC = Monday 05:00 KST, inside the `before 6am on monday` window of the configs. A run
  outside the window only handles vulnerability fixes.
- Renovate keeps the actions in the repo up to date too, so this workflow's own pins will show up in the first PRs.

## Cost

Public repos get free GitHub-hosted minutes. Measured above: 1 to 19 minutes per scan without a repo config. With
the recommended `ignorePaths`, `cluster` took about 1 minute on the laptop, so the weekly scheduled run is cheap.

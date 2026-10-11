# GitHub Actions

> **Status: decided on the central run (owner's choice, 2026-10-11).** The container path is verified on GitHub-hosted
> runners. The central workflow is in this repo; draft PRs with only `renovate.json5` are open in the three repos.
> `jyje-bot` is installed on the three repos and the central dry run is green (61 s; every repo is skipped until its
> config PR is merged). What is left needs the owner: merge the config PRs, one at a time.

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

## Which GitHub App: the existing `jyje-bot` or a new one

`jyje-bot` already exists (a **private** GitHub App, so its permissions are visible only to the owner). What the
logs of `jyje/claude-docker` show, and what they do not:

| Known | Not known |
|---|---|
| Installed on `jyje/claude-docker`; a token with `contents: write` and `pull-requests: read` is issued | The full permission list of the App |
| Convention: variable `APP_CLIENT_ID`, secret `APP_PRIVATE_KEY` (`actions/create-github-app-token`, `client-id` input) | Which other repos it is installed on |
| Secret values cannot be read back from GitHub, by anyone | Whether it has Issues, Workflows, Checks, Commit statuses write and Dependabot alerts read |

Renovate needs: Contents, Pull requests, Issues, Workflows, Checks, Commit statuses (all read and write), and
Dependabot alerts, Metadata (read). Both options need the owner:

| | Reuse `jyje-bot` | New dedicated App |
|---|---|---|
| Owner work | Add the missing permissions in the App settings, add the 3 repos to the installation, supply the private key again (generate a new key in the App settings) for 3 repos | Create the App, install it on the 3 repos, store its key in 3 repos |
| Blast radius | Adding `Workflows: write` and `Issues: write` also applies to `claude-docker` and every other repo it is installed on | Limited to the 3 repos |
| Names | Same `APP_CLIENT_ID` / `APP_PRIVATE_KEY` | Same names, so the template is identical either way |

Recommendation: a new App, for the narrower blast radius. The template works with either.

## Central run: one secret instead of three

Installing a GitHub App only lets it *access* a repo; a workflow still needs the private key to sign in as the App.
The key can be stored once if Renovate runs from one place. [`.github/workflows/renovate.yaml`](../.github/workflows/renovate.yaml)
in this repo (copy in `templates/github/renovate-central.yaml`) does that:

- `actions/create-github-app-token` with `owner: jyje` and `repositories: cluster, pifanctl, mungchilog` returns a
  token limited to those three repos.
- `RENOVATE_REPOSITORIES` lists the same three; `RENOVATE_REQUIRE_CONFIG=required` skips a repo until its
  `renovate.json5` is merged.
- Only the secret `APP_PRIVATE_KEY` is needed, and only in this repo. The client id is not a secret and is written in
  the workflow.
- Manual runs default to `dry-run: full`; the Sunday-night schedule creates PRs.

| | Per repo | Central |
|---|---|---|
| Secrets to register | 3 | 1 |
| Per repo needs | workflow + `renovate.json5` | `renovate.json5` only |
| Run log | each repo | this repo |
| Weak point | | one failure stops all three |

A personal account has no account-wide Actions secrets, so "install once, use everywhere" without storing the key
somewhere is not possible; an organization secret would do it but means moving the repos into an org. Mend's hosted
Renovate app is the "just install it" route, outside this pilot's container/CLI goal.

## Steps (central run)

1. **(owner, done 2026-10-12)** Install `jyje-bot` on `jyje/cluster`, `jyje/pifanctl`, `jyje/mungchilog`: Settings > Applications >
   Installed GitHub Apps > jyje-bot > Configure > Repository access. Check it with the workflow `🔑 check app install`
   (reports per repo; `claude-docker` is the control). On 2026-10-11 all three returned `Not Found`; on 2026-10-12 all succeed.
2. **(owner)** Check that `jyje-bot` has the permissions listed above (Issues, Workflows, Checks, Commit statuses
   write; Dependabot alerts read). Anything missing shows up as a failed step or a warning in the dry run.
3. **(owner)** Store the private key once, in this repo, from a terminal so it does not pass through chat:
   `gh secret set APP_PRIVATE_KEY --repo jyje/pilot-scan-renovatebot < <key>.pem`
4. Run the workflow `🤖 renovate` by hand with `dry-run: full`. Repos without a merged `renovate.json5` are skipped, so
   the first useful run comes after step 5.
5. **(owner)** Review and merge the config PRs below, one repo at a time. Then run the dry run again and read the log.
6. Run once with `dry-run: off`, check the first PRs and that their CI runs, then leave the Sunday-night schedule on.
7. Remove the overlapping Dependabot *version update* entries in `cluster` (`github-actions`) and `pifanctl`
   (`pip`, `docker`, `github-actions`) in separate PRs. Keep Dependabot security alerts.

## Config PRs (draft, not merged)

Each adds only `renovate.json5`. An earlier version of these PRs also carried a per-repo workflow; it was removed in a
follow-up commit when the central run was chosen.

| Repo | PR | Notes |
|---|---|---|
| mungchilog | [#112](https://github.com/jyje/mungchilog/pull/112) | base `dev` |
| pifanctl | [#85](https://github.com/jyje/pifanctl/pull/85) | CI `Workflows` (actionlint) and `Version bump` passed on the first version, as predicted from `check_version_bump.py` |
| cluster | [#166](https://github.com/jyje/cluster/pull/166) | `main` is protected |

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

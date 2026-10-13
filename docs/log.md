# Experiment log

Times are the machine's clock (KST). Tokens, keys and account ids are left out on purpose.

## 2026-10-10

- Researched Renovate: latest release `44.149.2`, AGPL-3.0-only. Docs note that v44 was released as a major by
  mistake, with no breaking change.
- Looked at the four repos through the GitHub API (read-only). `moongchilog` does not exist; `mungchilog` does.
  Default branch of mungchilog is `dev`.

## 2026-10-11

### Environment

- `gh` and `glab` (gitlab.com, HTTPS) logged in. Docker CLI present, daemon was down (OrbStack not running);
  started OrbStack, `docker info` OK. Pulled `ghcr.io/renovatebot/renovate:44.149.2`.

### Dry runs without any config (`scripts/dry-run.sh`, `RENOVATE_DRY_RUN=full`)

| Repo | Duration | Branches Renovate wants |
|---|---|---|
| mungchilog (`dev`) | 4 min 41 s | 42 |
| pifanctl | short | 4 |
| cluster | > 15 min | 117 |

Details per repo: [projects/](projects/).

### Findings

1. **Vendored Helm charts dominate `cluster`.** 169 `values.yaml`, 52 `Chart.yaml` and 10 upstream workflows inside
   charts. Only 3 files are the repo's own.
2. **Testing a repo config through the global config file is misleading for `ignorePaths`.** First attempt with
   `ignorePaths: ["helm/**"]` changed nothing. Wrong guess at first: that dot directories (`.github`) escape
   `helm/**`. Actual cause: `config:recommended` → `:ignoreModulesAndTests` sets `ignorePaths` after the global
   file's value. With `ignorePresets: [":ignoreModulesAndTests"]` added for the simulation, `helm/**` alone worked
   (cluster: 239 files → 3) and the extra `helm/**/.github/**` pattern was not needed and was removed.
   `--platform=local` does not read the repo's `renovate.json5` either.
3. **Regex custom manager needs `(?m)`** or `^` matches only the start of the file and finds zero dependencies.
4. **Version-bump CI in pifanctl** was checked in the script instead of assumed: only `sources/main.py`,
   `sources/pifanctl/` and `charts/<chart>/` (outside `ci/`) need a bump.
5. **First pifanctl config let the CI `python-version` go 3.14 → 3.15 inside the `actions` group.** Caught in the
   re-scan; a rule now keeps Python manual.
6. **Vulnerability fixes ignore the schedule** (mungchilog: `renovate/npm-dompurify-vulnerability`,
   `renovate/npm-undici-vulnerability` were prepared outside the Monday window).
7. Corrections to my own earlier notes: the file count for `cluster` without config is 239 (not 238); the first
   metric ("Open PR Count") counted approval-gated branches too, so branches were re-counted by distinct name.

### Before / after (distinct branches, final configs)

| Repo | No config | Recommended config | Majors waiting for approval |
|---|---|---|---|
| mungchilog | 42 | 24 | 13 |
| pifanctl | 4 | 2 | 1 |
| cluster | 117 | 1 | 1 |

### GitLab

- Created private sandbox `jyje/pilot-renovate-sample` (trimmed pifanctl copy + CI template + config).
- Project access token works on Free. Pipelines on shared runners failed: account not verified.
- Local container with `platform=gitlab`: dry run OK, then a real run opened MR `!1` and a Dependency Dashboard
  issue. Details: [03-gitlab.md](03-gitlab.md).
- Setting `ci_pipeline_variables_minimum_override_role` for the sandbox and starting a pipeline by hand were
  refused by the session's permission check, so that route was dropped.

### Published

- This repo was created as public `jyje/pilot-scan-renovatebot` and pushed (owner approved).

### GitHub-hosted dry run

- Wrote the secret-free `templates/github/dry-run.yaml` (default `GITHUB_TOKEN`, `RENOVATE_DRY_RUN=full`).
- First push was rejected: the local `gh` token had no `workflow` scope. The owner approved
  `gh auth refresh -s workflow` in the browser; the push then worked.
- One action SHA (`upload-artifact`) had been typed from memory and was wrong; replaced with the SHA looked up from
  the release tag.
- Run 1 failed in the summary step: the log file was written inside the container and never reached the runner.
  Run 2 failed the same way: `renovatebot/github-action` forwards only `RENOVATE_*`/`LOG_LEVEL`-style variables and
  mounts nothing. Fix: `additional-env-list` for `LOG_FILE`, `docker-volumes` for a log directory, and a writable
  host directory. Run 3 succeeded.
- All three repos then ran green on GitHub-hosted runners: pifanctl 62 s, mungchilog 141 s (42 branches, same as the
  laptop), cluster 1118 s (no repo config). Warning seen: `Cannot access vulnerability alerts` (the default token
  has no Dependabot alerts access).

### GitLab CI (after account verification)

- Owner finished identity verification. `glab ci run --branch main` created pipeline 2935178275; the `renovate` job
  succeeded on a shared runner in 57 s and opened MR `!2` (Renovate image tag 44.149.2 → 44.149.3 in
  `.gitlab-ci.yml`). Details: [03-gitlab.md](03-gitlab.md).

### GitHub rollout PRs

- Owner chose to reuse `jyje-bot`. Opened draft PRs adding the workflow and `renovate.json5`: mungchilog #112 (base
  `dev`), pifanctl #85, cluster #166. None merged.
- pifanctl CI on the PR: actionlint (`Workflows`) and `Version bump` pass, which matches the reading of
  `check_version_bump.py`.
- `rm -rf` with a variable path was blocked by a safety check while preparing the clones; rewritten without the
  removal.

### Switch to the central run

- Owner asked whether the App id and key must be stored in every repo. Answer: installing an App does not remove the
  need for the key; storing it once is possible by running Renovate from one place.
- I built the central workflow before the owner had chosen. The owner pointed out that no real choice had been
  offered; the decision (central run) was then made explicitly. Noted here so it is not repeated: ask first, and do not
  start the option I prefer.
- Removed the per-repo workflow from the three PR branches with a follow-up commit each, retitled the PRs
  ("add Renovate config") and rewrote their descriptions. Central workflow: `.github/workflows/renovate.yaml`.

### Central run, first attempts (2026-10-11)

- Owner stored `APP_PRIVATE_KEY` (and an `APP_ID`) in this repo. The central workflow's dry run failed at
  `create-github-app-token` with `Not Found - get-a-repository-installation-for-the-authenticated-app`.
- A key or client-id problem would give 401 "Bad credentials", not 404, so I added `.github/workflows/check-app-install.yaml`:
  it mints a token for each repo separately. With the control repo `claude-docker` (App known to be installed) it
  **succeeds**; `cluster`, `pifanctl` and `mungchilog` all return `Not Found`. Conclusion: key and client id are
  fine, and `jyje-bot` is **not installed** on the three target repos (it may be installed on other repos only).
- Fix is on the owner's side: Settings > Applications > Installed GitHub Apps > jyje-bot > Configure > Repository
  access, add the three repos.

### jyje-bot installed, central dry run (2026-10-12)

- Owner added `cluster`, `pifanctl`, `mungchilog` to the `jyje-bot` installation. `🔑 check app install`: all four
  repos (with the control) succeed.
- Central workflow `🤖 renovate`, `dry-run: full`: green in 61 s. The token was created for the three repos, all three
  were reached ("Repository started") and each was skipped with `config file not found`
  (`RENOVATE_REQUIRE_CONFIG=required`), because the config PRs are not merged yet. No warnings or errors.
- This does not yet prove the App's permissions: the vulnerability-alerts check and the write calls come after the
  config is read. They are exercised by the next dry run, after the first config PR is merged.

### cluster rolled out (2026-10-12, at the owner's request)

- Merged config PR cluster#166 (squash `0fc1165`; checks green, only `renovate.json5` changed, no review rule).
- Central dry run: cluster scanned with 3 files and 1 branch gated; pifanctl and mungchilog still skipped.
- Real run: Dependency Dashboard issue cluster#167 created by `jyje-bot` (Issues write works). No PR.
- The gated branch is the runner image bump `ubuntu 24.04 → 26.04`, which the `github-actions` manager reads as a
  dependency. I had described it as "an Actions major" earlier; corrected in `docs/projects/cluster.md`.
- `Cannot access vulnerability alerts`: Dependabot alerts are enabled (204) on all three repos, so the App is missing
  the **Dependabot alerts: read** permission. Owner action: App settings > Permissions & events > Repository
  permissions, then approve the permission update on the installation.

### Config PRs merged, central dry run (2026-10-14, at the owner's request)

- Merged pifanctl#85 (`c7bb893`) and mungchilog#112 (`5d73780`), both squash, only `renovate.json5` changed. Checked
  first that the `paths` filters of the image build workflows do not match a root `renovate.json5`, so no image build
  or deploy is triggered.
- Central dry run (71 s): all three repos scanned with their own config, no errors. mungchilog 16 branches (13 gated by
  approval), pifanctl 3 (1 gated), cluster 1 (gated).
- New finding: pifanctl showed `renovate.python-3.x`, a Python 3.14 → 3.15 move of both Dockerfiles and
  `.python-version`. Python 3.15 was released after my earlier scans. My rule only covered the workflow's
  `python-version`. Extended it to `dockerfile` and `pyenv`, re-scanned (branch gone) and opened pifanctl#93. Not merged.
- Still `Cannot access vulnerability alerts` on all three repos: the App needs Dependabot alerts: read.

### Not done yet

- Merging pifanctl#93 (owner) before the Sunday-night schedule.
- `jyje-bot` needs Dependabot alerts: read (owner).
- First real run for pifanctl and mungchilog, and the first Renovate PR with CI. The Sunday-night schedule is the next
  trigger.

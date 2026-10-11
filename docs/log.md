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

### Not done yet

- Installing `jyje-bot` on the three repos, confirming its permissions, setting `APP_CLIENT_ID` and `APP_PRIVATE_KEY`
  (owner only; see [02-github-action.md](02-github-action.md)), then merging the PRs and running the workflow once as a
  dry run. The container path itself is already verified on hosted runners.

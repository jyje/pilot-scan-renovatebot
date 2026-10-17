# Recommendations

What to do next, after the rollout of 2026-10-11 to 2026-10-15. Each item says why, based on what the runs showed.
Status as of 2026-10-18. Items marked **done** were carried out; the rest need the owner or a later date.

## Before the next scheduled run (Sunday 16:00 UTC, Monday 01:00 KST)

| Item | Who | Why |
|---|---|---|
| **Done 2026-10-16**: merged [pifanctl#93](https://github.com/jyje/pifanctl/pull/93) (`e49de47`); the central dry run no longer shows `renovate/python-3.x` | | Without it the run opens a Python 3.14 → 3.15 PR for both Dockerfiles and `.python-version`, while CI stays on 3.14 |
| Give `jyje-bot` **Dependabot alerts: read** | owner | Every run logs `Cannot access vulnerability alerts`. The owner chose to keep Renovate's vulnerability PRs on next to Dependabot security updates (2026-10-18), so the App needs this permission; expect security fixes to get a PR from both tools |

## After the first real PRs

| Item | Why |
|---|---|
| **Decided 2026-10-18: keep Dependabot and Renovate side by side** | The owner chose to run both on the same ecosystems (option A) rather than split them. The same update can get one PR from each tool; merging either updates the dependency and the other tool closes its PR on its next run. The removal PR cluster#168 was closed. pifanctl#96 had already been merged on 2026-10-16, so [pifanctl#101](https://github.com/jyje/pifanctl/pull/101) restores `dependabot.yaml`. Rejected alternative: split by ecosystem (no duplicates, but Renovate would cover much less) |
| **Done 2026-10-16**: this repo is in the scan | `jyje-bot` is installed here (checked first, since one missing installation would fail the token for all repos). `renovate.json5` covers the workflows, the templates (extra `managerFilePatterns`), `.gitlab-ci.yml` and the image in `scripts/dry-run.sh` (regex). The `renovate-version` input is already read by the `github-actions` manager, so the regex is limited to the script to avoid two managers editing one string. Dry run: one `renovate runtime` group PR (Renovate 44.149.2 → 44.164.6, action pins) and the runner 26.04 bump gated |
| Make failures visible | One central run serves three repos, so one failure stops all of them. GitHub mails scheduled-workflow failures to the person who last changed the cron; confirm that mail arrives, or check the run summary weekly |

## Per repository

| Repo | Recommendation |
|---|---|
| cluster | Decide on the gated runner bump `ubuntu 24.04 → 26.04` in [#167](https://github.com/jyje/cluster/issues/167); the other two repos already use 26.04. The vendored-chart watch from the experiment works as a weekly report, not as a PR (Renovate would only edit `Chart.yaml`'s version) |
| pifanctl | Check that the first PR passes CI, including `Version bump`. Decide whether all actions should be pinned by SHA (`helpers:pinGitHubActionDigests`); today it is a mix of SHA and tags |
| mungchilog | 13 majors wait on the dashboard. No extra Node rule is needed: without a config Renovate proposed Node 26, but with `config:recommended` (its `workarounds:nodeDockerVersioning`) it proposes the LTS `node-24.x`. Handle `postgres 17 → 18` as a planned migration, not as a dashboard checkbox. Dependabot's open security PR [mungchilog#111](https://github.com/jyje/mungchilog/pull/111) (since 2026-09-29) is still waiting for review |

## Security and housekeeping

| Item | Why |
|---|---|
| Review `jyje-bot`'s blast radius | It is installed on other repos too (`claude-docker` at least), and permissions added for Renovate apply there as well. A Renovate-only App remains an option |
| Remove or label the unused `APP_ID` secret | The central workflow uses the client id written in the file, not `APP_ID` |
| Consider `osvVulnerabilityAlerts: true` | Platform-independent vulnerability data for direct dependencies (npm, pypi, ...). Works the same on GitHub and GitLab; not tested here |
| Automerge later, not now | Only useful where required checks exist. mungchilog runs no CI for config-only changes; revisit after a few weeks of PRs |

## Done on 2026-10-15

- GitLab sandbox `jyje/pilot-renovate-sample` cleaned up: MRs `!1`, `!2` and both Dependency Dashboard issues closed,
  the `renovate` project token revoked (the two local test tokens had already expired), project **archived**.
  Deleting it is irreversible and left to the owner:

  ```bash
  glab repo delete jyje/pilot-renovate-sample
  ```

# Recommendations

What to do next, after the rollout of 2026-10-11 to 2026-10-15. Each item says why, based on what the runs showed.
Status as of 2026-10-15.

## Before the next scheduled run (Sunday 16:00 UTC, Monday 01:00 KST)

| Item | Who | Why |
|---|---|---|
| Merge [pifanctl#93](https://github.com/jyje/pifanctl/pull/93) | owner | Without it the run opens a Python 3.14 → 3.15 PR for both Dockerfiles and `.python-version`, while CI stays on 3.14 |
| Give `jyje-bot` **Dependabot alerts: read** | owner | Every run logs `Cannot access vulnerability alerts`; alerts are enabled on all three repos, so vulnerability-fix PRs (which ignore the schedule) are off until the App can read them |

## After the first real PRs

| Item | Why |
|---|---|
| Remove Dependabot *version updates* that overlap | cluster (`github-actions`) and pifanctl (`pip`, `docker`, `github-actions`) are now covered by Renovate too, so each update would get two PRs. One PR per repo, after Renovate's first PRs look right. Keep Dependabot security alerts. cluster's `helm` entry points at `/helm/<group>`, where there is no `Chart.yaml`; check whether it ever produced anything before keeping it |
| Add this repo to the scan | Nobody updates the central workflow's own action pins and `renovate-version: 44.149.2`. With a `renovate.json5` here and the repo in the list, Renovate keeps its own runner current, as it did on GitLab (MR `!2` bumped the Renovate image) |
| Make failures visible | One central run serves three repos, so one failure stops all of them. GitHub mails scheduled-workflow failures to the person who last changed the cron; confirm that mail arrives, or check the run summary weekly |

## Per repository

| Repo | Recommendation |
|---|---|
| cluster | Decide on the gated runner bump `ubuntu 24.04 → 26.04` in [#167](https://github.com/jyje/cluster/issues/167); the other two repos already use 26.04. The vendored-chart watch from the experiment works as a weekly report, not as a PR (Renovate would only edit `Chart.yaml`'s version) |
| pifanctl | Check that the first PR passes CI, including `Version bump`. Decide whether all actions should be pinned by SHA (`helpers:pinGitHubActionDigests`); today it is a mix of SHA and tags |
| mungchilog | 13 majors wait on the dashboard. A rule that follows only Node LTS majors makes the Node decision automatic. Handle `postgres 17 → 18` as a planned migration, not as a dashboard checkbox |

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

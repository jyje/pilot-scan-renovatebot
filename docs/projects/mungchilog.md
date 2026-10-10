# jyje/mungchilog

Personal travel itinerary app. TypeScript, two npm apps, Docker image built in GitHub Actions, Helm chart in the
same repo, deployed by Argo CD from the `stg` and `prd` branches.

Note: the project is `mungchilog` (the request said "moongchilog").

## What Renovate sees (no config)

Scan of branch `dev`, 4 min 41 s on a cold container.

| Manager | Files |
|---|---|
| `npm` | `apps/server/package.json`, `apps/web/package.json` (separate lock files, no root workspace) |
| `dockerfile` | `apps/server/Dockerfile`, `apps/server/Dockerfile.release` |
| `docker-compose` | `docker-compose.yaml`, `docker/docker-compose.postgres.yaml` |
| `github-actions` | 5 workflows |
| `helm-values` | `charts/mungchilog/values.yaml` |

`skills-lock.json` is not picked up by any manager, so there is nothing to ignore.

Without config Renovate would open **42 branches** at once (many `v4 → v7` style action bumps, Node `22 → 26`,
`typescript 5 → 7`, `zod 3 → 4`, …).

## Things specific to this repo

- Default branch is `dev`. `stg` and `prd` receive code only through `promote-image.yml`, so Renovate targets `dev`
  only (`baseBranchPatterns`).
- `guard-app-source.yml` runs only on PRs to `stg` and `prd`, so it does not block Renovate PRs into `dev`.
- No `dependabot.yml` and no Renovate config exist today, so nothing needs to be switched off. Dependabot
  *security* updates (GitHub setting) are separate and can stay on.
- Argo CD Image Updater picks image tags from GHCR (`allowTags` regex in the `cluster` repo). Renovate only edits
  files in this repo, so the two do not touch each other.
- Vulnerability fixes bypass the schedule: the simulated run, made outside the Monday window, still wanted to open
  `renovate/npm-dompurify-vulnerability` and `renovate/npm-undici-vulnerability`.

## Recommended config

[`projects/mungchilog/renovate.json5`](../../projects/mungchilog/renovate.json5)

| Setting | Reason |
|---|---|
| `baseBranchPatterns: ["dev"]` | See above |
| `schedule: before 6am on monday`, `Asia/Seoul` | One quiet window per week |
| `prConcurrentLimit: 5`, `prHourlyLimit: 2` | Upper bound on PR noise |
| `commitMessagePrefix: "🤖 ci(deps):"`, `semanticCommits: disabled` | Matches `git-commit-helper` bot rule |
| majors → `dependencyDashboardApproval` | 13 of the 24 branches are majors; they wait for a tick on the dashboard |
| non-major npm grouped per app (`apps/server`, `apps/web`) | One PR per app instead of one per package |
| non-major GitHub Actions grouped | Same |

## Result

| | Branches | Majors waiting for approval |
|---|---|---|
| No config | 42 | 0 |
| Recommended config | 24 | 13 |

So at most 11 PRs open on the first Monday (grouped), and the 13 majors appear as checkboxes. Plus the
vulnerability branches when advisories exist.

## Open questions

- Node base image: `22-alpine → 26-alpine` is gated as a major. Decide if the project follows the Node LTS line;
  if so add an `allowedVersions` rule for `node`.
- Whether the real PR runs CI correctly on `dev` is checked in the GitHub Action step
  ([02-github-action.md](../02-github-action.md)).

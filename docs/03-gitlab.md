# GitLab (gitlab.com)

Same idea as GitHub, tested on a sandbox project `jyje/pilot-renovate-sample` (private): a trimmed copy of the
`pifanctl` layout (pip requirements, Dockerfiles, two Helm charts) plus the template from
[`templates/gitlab/.gitlab-ci.yml`](../templates/gitlab/.gitlab-ci.yml) and a `renovate.json5`.

## What worked

| Step | Result |
|---|---|
| Create the project with `glab repo create` | Works. `git push` needs a credential helper: `git -c credential.helper='!glab auth git-credential' push` (plain `git push` waited for a password forever) |
| Project access token on the **Free** plan (`api`, `write_repository`, role Developer, with an expiry date) | Works; the token value is shown once at creation |
| Store the token as a masked CI/CD variable `RENOVATE_TOKEN` | Works |
| Renovate container with `platform=gitlab` against the project | Works. Reads the repo's `renovate.json5`; found pip, Docker, Helm values, pyenv and `.gitlab-ci.yml` (manager `gitlabci`) |
| Real run (local container) | Opened MR `!1 🤖 ci(deps): Update python` (`typer`, `matplotlib`) and the Dependency Dashboard issue. `kubernetes 37` is listed under "Pending Approval" |

The `commitMessagePrefix` gives the same `🤖 ci(deps): ...` titles as on GitHub, so the `git-commit-helper` bot rule
carries over unchanged.

## CI on gitlab.com shared runners

After the owner finished identity verification, a pipeline started with `glab ci run` ran the `renovate` job on a
shared runner (`saas-linux-small-amd64`): **success in 57 s**. It used the repo's `renovate.json5` and the masked
`RENOVATE_TOKEN` variable, and it opened MR `!2 🤖 ci(deps): Update ghcr.io/renovatebot/renovate Docker tag to v44.149.3`,
the CI file's own pinned Renovate image (manager `gitlabci`). So Renovate keeps the job that runs it up to date.
Note: that run was a real run, not a dry run, because `RENOVATE_DRY_RUN` could not be set as a variable in this
session. In a real project, put `RENOVATE_DRY_RUN=full` in the schedule's variables for the first run.

Before verification, both push pipelines had failed immediately with "The pipeline failed due to the user not being
verified". Identity verification (phone or card) is something only the account owner can do. Other ways around it,
not needed in the end: a project runner on your own machine, or running Renovate from GitHub Actions against the
GitLab project with `platform=gitlab`.

The free-plan compute-minute quota is not visible through the API (`shared_runners_minutes_limit` is `null`), so it is
not recorded here. One scan of this small project used about 1 minute.

## Differences from GitHub worth knowing

| | GitHub | GitLab |
|---|---|---|
| Auth | GitHub App (installation token) | Project/group access token (expires, must be renewed) |
| Who the PRs come from | the App's bot | the token's bot user (`project_<id>_bot_...`) |
| Trigger | `schedule` / `workflow_dispatch` | Pipeline schedule / manual pipeline |
| Pipeline variables when starting manually | workflow inputs | Blocked by default on new projects (`ci_pipeline_variables_minimum_override_role = no_one_allowed`); put values in the project's CI/CD variables or the schedule instead |
| Release notes in PRs | works | needs a `GITHUB_COM_TOKEN` for notes of GitHub-hosted dependencies; without it Renovate logs "Skipping release notes retrieval" and goes on |
| Reading config | `renovate.json5` in the repo | same file, same options |

## Cleanup

The two local access tokens used for the tests expire on 2026-10-12. The CI variable token (`renovate`) expires on
2026-12-31. Revoke from the project's Settings > Access tokens if the sandbox is no longer needed.

# Skills analysis

Which skills from [jyje/skills](https://github.com/jyje/skills) (and the per-repo `.claude/skills/`) matter
for this pilot, and where they collide with what Renovate can do.

## From jyje/skills

| Skill | Verdict | Why |
|---|---|---|
| `git-commit-helper` | Apply as is | Has a dedicated "Automated / Bot Commits" rule: bots use `🤖 ci(<scope>): ...`, configured in the bot itself. For Dependabot that is `commit-message.prefix`; for Renovate the equivalent is `semanticCommits: "disabled"` plus `commitMessagePrefix: "🤖 ci(deps):"`. Every proposed `renovate.json5` does this. Commits in this repo follow the same format. |
| `centered-readme` | Apply as is | README header of this repo. |
| `make-pilot-python` | Apply, trimmed | EN/KO README and `docs/` layout. `uv init` and `src/` are skipped because this pilot holds no Python code. |
| `python-lint` | Conditional | Only if Python scripts are added here. pifanctl installs from `sources/requirements.*.txt` (pip), not uv, so the "uv-managed project" assumption of this skill does not describe the dependency files Renovate sees there. |
| `authentik-container-admin`, `make-pilot-agent-project` | Not relevant | |

## Skills inside the scanned repos (jyje/cluster)

These describe workflows that change the same files Renovate would touch.

| Skill | Relation to Renovate |
|---|---|
| `helm-chart-vendor` | Owns every change under `helm/<group>/<chart>-<version>/` (`helm pull`, rename directory, keep older versions). Renovate cannot do the pull and rename, so `helm/**` is excluded from scanning. |
| `helm-extraresources-patcher` | Patches vendored charts after the pull. Any automated chart bump would drop these patches. Another reason to keep Renovate away from `helm/**`. |
| `floating-image-tag-sync` | Keeps floating tags such as `"0.10"` in step with the chart. A Renovate `docker`/`helm-values` manager would try to pin them. The `enabledManagers` list in the cluster config keeps those managers off. |
| `microk8s-release-watch` | Weekly shell workflow that watches the Snap Store. A Renovate custom datasource could replace it, but it works and is out of scope for now. |
| `manifest-group`, `ambient-namespace-enroll`, `litellm-update`, `authentik-container-admin` | No overlap with dependency updates. |

## Draft idea: `renovate-config` skill

Not created. A skill that, for a repo type (Python with pip, npm apps, GitOps with vendored charts), produces a
`renovate.json5` with these defaults, runs the config validator, and does a dry run before anything is
committed. The rules it would encode are in [`docs/projects/`](projects/) and [`log.md`](log.md). Whether it belongs
in `jyje/skills` is the owner's call.

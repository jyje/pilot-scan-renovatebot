# jyje/cluster

GitOps repo of the home cluster: Argo CD `Application` manifests in `clusters/r4spi/apps/`, and **vendored copies of
Helm charts** under `helm/<group>/<chart>-<version>/` (several versions of one chart side by side, kept on purpose
so deployments stay reproducible if an upstream disappears).

## What Renovate sees (no config)

Scan of branch `main`. This was the heaviest scan: it ran for over 15 minutes and wanted **117 branches**.

| Manager | Files | Where they come from |
|---|---|---|
| `helm-values` | 169 | `values.yaml` of every vendored chart and subchart |
| `helmv3` | 52 | `Chart.yaml` of vendored charts (subchart `dependencies`) |
| `github-actions` | 12 | 2 real workflows + 10 upstream workflows shipped inside vendored `open-webui` charts |
| `dockerfile` | 3 | `helm/grafana/loki-*/src/helm-test/Dockerfile` |
| `helm-requirements`, `cloudbuild` | 1 each | inside vendored charts |
| `pip_requirements` | 1 | `docs/diagrams/requirements.txt` |

Only 3 of those files are the repo's own: `.github/workflows/microk8s-track.yaml`, `probe.yaml`,
`docs/diagrams/requirements.txt`. Everything else is upstream content that the `helm-chart-vendor` and
`helm-extraresources-patcher` skills own.

The `clusters/r4spi/apps/*.yaml` Applications point at paths inside this repo (`path: helm/...`) or at other
`jyje/*` repos, so the Argo CD manager finds no chart `targetRevision` to track.

## Recommended config

[`projects/cluster/renovate.json5`](../../projects/cluster/renovate.json5)

| Setting | Reason |
|---|---|
| `ignorePaths: ["helm/**"]` | Vendored charts are changed only by the vendoring skills |
| `enabledManagers: ["github-actions", "pip_requirements"]` | Only what Renovate can own here. Also keeps the managers away from floating image tags (`floating-image-tag-sync`) |
| majors → dashboard approval | Actions majors wait for a tick |
| group `actions` | Same as the existing `dependabot.yaml` |
| Common block | Schedule, limits, `🤖 ci(deps):` prefix |

## Result

| | Branches | Files scanned |
|---|---|---|
| No config | 117 | 239 |
| Recommended config | 1 (a major, waiting for approval) | 3 |

Effectively no PR until someone ticks the dashboard box, and then one PR for the Actions bump.

## Dependabot

`.github/dependabot.yaml` has `github-actions` (`/`) and `helm` (`/helm/*`). Renovate takes over `github-actions`.
The `helm` entry looks at `/helm/<group>`, where there is no `Chart.yaml` (charts live one level deeper, in
versioned directories); whether it ever produced anything was not verified here. Keep or remove it as a separate
decision. Nothing was changed in the repo.

## Experiment: new-version watch for vendored charts

Question: can Renovate at least *tell* when a vendored chart has a newer upstream release?

Yes, with a regex custom manager over `helm/*/*/Chart.yaml` and a Helm `registryUrls` per chart
([`experiments/vendored-chart-watch.json5`](../../projects/cluster/experiments/vendored-chart-watch.json5)). Four
charts were wired up as a test:

| Vendored | Newest upstream seen |
|---|---|
| `cert-manager v1.21.1` (latest vendored) | `v1.21.2` |
| `argo-cd 10.4.2` (latest vendored) | `10.10.2` |
| `ingress-nginx`, `sealed-secrets` | resolved too |

Findings:

- The regex needs `(?m)`; without it `^` only matches the start of the file and zero dependencies are found.
- Charts without a `registryUrls` rule resolve to nothing (`no-update`). The `helm/README.md` table of providers has
  the URLs, so a full rule list is mechanical.
- Old vendored versions (`cert-manager-v1.16.0`, …) are reported as outdated too. Only the newest directory per
  chart matters, so a real setup would need to filter or ignore the rest.
- **Renovate would edit `Chart.yaml`'s `version` in a PR**, which is wrong for a vendored copy (the content under
  the directory would not change). So this is only useful as a *report* (dry run `lookup`, or an issue/dashboard),
  not as an auto-PR. Not wired into a workflow.

Not tested: `postUpgradeTasks` running `helm pull` and renaming the directory. It needs a self-hosted Renovate with
`allowedCommands`, plus the patches from `helm-extraresources-patcher` re-applied afterwards; judged not worth it
for now.

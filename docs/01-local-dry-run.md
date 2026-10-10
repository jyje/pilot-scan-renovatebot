# Local dry run with Docker

Scan a real repo with the Renovate container and write **nothing** to it.

## Prerequisites

- Docker daemon running (on this machine: OrbStack)
- `gh` logged in; its token is read-only enough for a dry run on public repos

## Run

```bash
scripts/dry-run.sh jyje/mungchilog                              # no repo config: what does Renovate do by default?
RUN_TAG=sim__ scripts/dry-run.sh jyje/mungchilog <config.json5> # with a proposed config
```

The script runs `ghcr.io/renovatebot/renovate:44.149.2` with `RENOVATE_DRY_RUN=full`, `LOG_FORMAT=json`,
`LOG_LEVEL=debug` and the token passed as an environment variable by name (never printed). Logs go to `out/`
(git-ignored).

## Read the log

```bash
# managers and files that were found
jq -r 'select(.msg=="packageFiles with updates") | .config | to_entries[] | "\(.key): \([.value[].packageFile]|join(", "))"' out/<log>.jsonl

# dependencies that have updates
jq -r 'select(.msg=="packageFiles with updates") | .config | to_entries[] | .key as $m | .value[] | .packageFile as $pf
  | (.deps // [])[] | select((.updates|length)>0) | "\($m)\t\($pf)\t\(.depName)\t\(.currentValue)"' out/<log>.jsonl

# branches Renovate evaluated, and which ones wait for dashboard approval
jq -r 'select(.msg|test("^branchExists=")) | .branch' out/<log>.jsonl | sort -u | wc -l
jq -r 'select(.msg|test("creation is disabled because dependencyDashboardApproval"))|.msg' out/<log>.jsonl
```

## Testing a repo config before it is committed

Renovate reads a repo's `renovate.json5` only from the repo. To try a config without committing it, pass it as the
*global* config file. Two things to know:

1. **Presets override it.** `config:recommended` includes `:ignoreModulesAndTests`, which sets `ignorePaths`. In the
   global-config simulation that list replaced the one in the file, so `ignorePaths: ["helm/**"]` did nothing. For
   the simulation only, add `ignorePresets: [":ignoreModulesAndTests"]`. In a real repo config the file's own
   `ignorePaths` wins and no such workaround is needed (the sim then matched what is expected).
2. `--platform=local` does not read `renovate.json5` from the working directory either, so it is not an
   alternative.

Validate syntax separately:

```bash
docker run --rm -v "$PWD/projects/<repo>/renovate.json5:/work/renovate.json5:ro" -w /work \
  ghcr.io/renovatebot/renovate:44.149.2 renovate-config-validator --strict renovate.json5
```

## Cost

First run on a cold container: 4 min 41 s for mungchilog; over 15 min for `cluster` without `ignorePaths`; about
1 min for `cluster` with it.

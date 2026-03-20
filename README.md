# luacheck

A Docker action that runs [luacheck](https://luacheck.readthedocs.io/) with Lua 5.1. Optionally runs a custom Lua script after luacheck.

## Usage

```yaml
jobs:
  luacheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - name: Luacheck linter
        uses: dekallo/luacheck@main
        with:
          args: -q
```

### With a custom script

```yaml
      - uses: dekallo/luacheck@main
        with:
          args: -q
          custom_script: scripts/validate.lua
          custom_args: .
```

### With options

```yaml
      - uses: dekallo/luacheck@main
        with:
          args: --codes --ranges
          config: https://raw.githubusercontent.com/your-org/config/main/.luacheckrc
          annotate: warning
```

### Job summary (optional)

Set **`job_summary: true`** to append a short summary to the workflow **Summary** tab ([`GITHUB_STEP_SUMMARY`](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#adding-a-job-summary)).

```yaml
      - uses: dekallo/luacheck@main
        with:
          args: -q
          job_summary: true
```

### Inputs

| Input           | Default | Description                                                                                                                                                                  |
| --------------- | ------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `files`         | `.`     | Paths passed to luacheck (default: whole repo)                                                                                                                               |
| `path`          | `.`     | Working directory (relative to workspace)                                                                                                                                    |
| `args`          | `""`    | Extra luacheck CLI arguments (see below)                                                                                                                                     |
| `config`        | `""`    | URL to custom `.luacheckrc`                                                                                                                                                  |
| `annotate`      | `none`  | `none`, `warning`, or `error` — show issues as PR annotations (incompatible with `-qq`/`-qqq`)                                                                               |
| `custom_script` | `""`    | URL or path (relative to `path`, or absolute) for a Lua script run after luacheck                                                                                            |
| `custom_args`   | `"."`   | Arguments passed to the custom script                                                                                                                                        |
| `run_luacheck`  | `true`  | Set `false` to run only the custom script                                                                                                                                  |
| `fail_fast`     | `false` | If true, stop after the first failing step; if false, run luacheck and script (if set) and fail if either failed                                                             |
| `job_summary`   | `false` | Markdown summary on the workflow Summary tab                                                                                                                                 |

### Common `args` options

| Arg          | Description                              |
| ------------ | ---------------------------------------- |
| `-q`         | Suppress output for files with no issues |
| `-qq`        | Suppress warning output (summary only)   |
| `-qqq`       | Summary line only                        |
| `--codes`    | Show warning/error codes (e.g. `W211`)   |
| `--ranges`   | Show column ranges for issues            |
| `--no-cache` | Disable luacheck’s cache                 |

Full reference: [luacheck CLI docs](https://luacheck.readthedocs.io/en/stable/cli.html)

### File modifications

Custom scripts run with the workspace mounted; they can read/write repo files.

## Repo structure

| Path            | Purpose                                                                               |
| --------------- | ------------------------------------------------------------------------------------- |
| `action.yml`    | Docker action (`docker://ghcr.io/dekallo/luacheck:latest`)                            |
| `Dockerfile`    | Alpine image with luacheck, Lua 5.1, curl                                             |
| `entrypoint.sh` | Luacheck and/or custom script; optional `job_summary` |
| `test/`         | Fixtures and workflow job examples ([test/README.md](test/README.md))                 |

The [Luacheck workflow](.github/workflows/luacheck.yml) self-tests the action.

## Setup

Push the repo and run [.github/workflows/build.yml](.github/workflows/build.yml) to publish `ghcr.io/dekallo/luacheck`.

Forks: point `image` in `action.yml` at your registry (e.g. `docker://ghcr.io/your-org/your-repo:latest`).

## Local use

Build and run the container locally (mounts current directory as workspace):

```bash
docker build -t luacheck .
docker run -v "$(pwd):/workspace" luacheck
```

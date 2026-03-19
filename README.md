# luacheck

A GitHub Action that runs [luacheck](https://luacheck.readthedocs.io/) (a static analyzer for Lua) in Docker. luacheck and Lua 5.1 are pre-installed (Alpine + apk), so jobs start immediately. Optionally runs a custom Lua script after luacheck (e.g. for code generation or additional validation).

## Usage

Same config for both modes; the action auto-detects. **Job mode** (recommended) yields separate steps in the Actions UI; **host mode** runs everything in one step.

### Job mode (recommended)

By defining `container:` the action runs inside the docker environment.

```yaml
# .github/workflows/luacheck.yml
name: Luacheck
on: [push, pull_request]

jobs:
  luacheck:
    runs-on: ubuntu-latest
    container: ghcr.io/dekallo/luacheck:latest
    steps:
      - uses: actions/checkout@v6
      - uses: dekallo/luacheck@main
        with:
          files: src lib
          args: -q
          custom_script: scripts/validate.lua
```

### Host mode

Action runs entirely on the host in a single step.

```yaml
# .github/workflows/luacheck.yml
name: Luacheck
on: [push, pull_request]

jobs:
  luacheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: dekallo/luacheck@main
        with:
          files: src lib
          args: -q
          custom_script: scripts/validate.lua
```

### With options

```yaml
      - uses: dekallo/luacheck@main
        with:
          files: src lib
          args: --codes --ranges
          config: https://raw.githubusercontent.com/your-org/config/main/.luacheckrc
          annotate: warning  # or "error" — emits GitHub annotations on PRs
```

The [Luacheck workflow](.github/workflows/luacheck.yml) self-tests the action; the examples above show how to use it.

### Luacheck + custom test/deploy script

```yaml
      - uses: dekallo/luacheck@main
        with:
          args: -q
          config: https://raw.githubusercontent.com/your-org/config/main/.luacheckrc
          custom_script: scripts/generate_options.lua
          custom_args: module1.toc module2.toc
```

### Inputs


| Input           | Default | Description                                                                                                                                                                  |
| --------------- | ------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `files`         | `.`     | Files, rockspecs, or directories to check                                                                                                                                    |
| `path`          | `.`     | Working directory (relative to workspace)                                                                                                                                    |
| `args`          | `""`    | Extra luacheck CLI arguments (see below)                                                                                                                                     |
| `config`        | `""`    | URL to custom `.luacheckrc`                                                                                                                                                  |
| `annotate`      | `none`  | `none`, `warning`, or `error` — show issues as PR annotations (incompatible with `-qq`/`-qqq`)                                                                               |
| `custom_script` | `""`    | URL or path (relative to `path`, or absolute) to a Lua script to run after luacheck. Runs in the working directory and can modify repo files (e.g. code generation / tests). |
| `custom_args`   | `"."`   | Arguments passed to the custom script                                                                                                                                        |
| `run_luacheck`  | `true`  | When false, skip luacheck (script-only mode)                                                                                                                                 |
| `fail_fast`     | `false` | When true, exit on first failure (luacheck or script). When false, run both and exit with failure if either failed.                                                          |


### Common `args` options


| Arg          | Description                              |
| ------------ | ---------------------------------------- |
| `-q`         | Suppress output for files with no issues |
| `-qq`        | Suppress warning output (summary only)   |
| `-qqq`       | Summary line only                        |
| `--codes`    | Show warning/error codes (e.g. `W211`)   |
| `--ranges`   | Show column ranges for issues            |
| `--no-cache` | Disable cache (action already uses this) |


Full reference: [luacheck CLI docs](https://luacheck.readthedocs.io/en/stable/cli.html)

### File modifications

Scripts can read/write repo files; no extra bind mounts needed. GitHub mounts the workspace in job mode; the action mounts it in host mode.

## Repo structure


| Path            | Purpose                                                                               |
| --------------- | ------------------------------------------------------------------------------------- |
| `action.yml`    | Composite action; detects job vs host mode, runs steps accordingly                    |
| `Dockerfile`    | Alpine image with luacheck, Lua 5.1, curl                                             |
| `entrypoint.sh` | Parses inputs, runs luacheck and/or custom script (supports subcommands for job mode) |
| `test/`         | Fixtures and workflow job examples ([test/README.md](test/README.md))                 |


## Setup

**First-time setup:** Push this repo and let the [build workflow](.github/workflows/build.yml) run. It publishes the image to `ghcr.io/dekallo/luacheck`. After that, the action is ready to use.

**Forking:** Update the image reference in `action.yml` to your own GHCR path (e.g. `ghcr.io/your-org/luacheck`).

## Local use

Build and run the container locally (mounts current directory as workspace):

```bash
docker build -t luacheck .
docker run -v "$(pwd):/workspace" luacheck
```

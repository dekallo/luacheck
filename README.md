# luacheck

A luacheck GitHub Action that runs in Docker. **No setup, instant run** — luacheck is pre-installed (Alpine + apk), so jobs start immediately. Self-contained, no external image dependencies.

## Usage

```yaml
# .github/workflows/luacheck.yml
name: Luacheck
on: [push, pull_request]

jobs:
  luacheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dekallo/luacheck@main
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

### Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `files` | `.` | Files, rockspecs, or directories to check |
| `path` | `github.workspace` | Working directory |
| `args` | `""` | Extra luacheck CLI arguments (see below) |
| `config` | `""` | URL to custom `.luacheckrc` |
| `annotate` | `none` | `none`, `warning`, or `error` — show issues as PR annotations (incompatible with `-qq`/`-qqq`) |

### Common `args` options

| Arg | Description |
|-----|-------------|
| `-q` | Suppress output for files with no issues |
| `-qq` | Suppress warning output (summary only) |
| `-qqq` | Summary line only |
| `--codes` | Show warning/error codes (e.g. `W211`) |
| `--ranges` | Show column ranges for issues |
| `--no-cache` | Disable cache (recommended in CI) |

Full reference: [luacheck CLI docs](https://luacheck.readthedocs.io/en/stable/cli.html)

## Setup

**First-time setup:** Push this repo and let the [build workflow](.github/workflows/build.yml) run. It publishes the image to `ghcr.io/dekallo/luacheck`. After that, the action is ready to use.

If you fork this repo, update the image reference in `action.yml` to your own GHCR path.

## Local use

```bash
docker build -t luacheck .
docker run -v "$(pwd):/workspace" luacheck
```

## Why Docker?

This action uses a pre-built image — luacheck is already there, so the job starts immediately.

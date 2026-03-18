# Test fixtures

Fixtures used by the [Luacheck workflow](../.github/workflows/luacheck.yml). Each workflow job validates a specific combination of inputs and serves as a copy-paste example.

## Fixtures

| File | Purpose |
|------|---------|
| `sample.lua` | Valid Lua for luacheck (passes) |
| `bad.lua` | Invalid Lua (undefined variable) — luacheck fails |
| `validate.lua` | Test script. Supports `--fail` (exit 1), `--echo a b c` (print args) |
| `write.lua` | Writes `test/.written-by-script` — validates scripts can modify repo |
| `luacheckrc.minimal` | Minimal config for remote-config tests |

## Workflow jobs

### Execution modes

- **luacheck-only** — Luacheck only, no script
- **script-only** — Script only (`run_luacheck: false`)
- **both-pass** — Luacheck + script, both pass
- **both-disabled** — Neither (no-op, exit 0)

### Failure modes (expect container to fail)

- **luacheck-fails** — Luacheck fails on `bad.lua`
- **script-fails** — Script exits 1 (`--fail`)
- **fail_fast-luacheck-fails** — `fail_fast: true`, luacheck fails, script never runs
- **fail_fast-script-fails** — `fail_fast: true`, script fails
- **run-both-luacheck-fails** — `fail_fast: false`, both run, luacheck fails
- **run-both-script-fails** — `fail_fast: false`, both run, script fails

### Input variations

- **config-url** — Config from raw GitHub URL
- **args-quiet** — Luacheck `-q`
- **script-from-url** — Script from raw GitHub URL
- **script-args** — Multiple `test_args` (`--echo foo bar`)
- **script-writes-repo** — Script writes file, verify with `test -f`
- **path-subdir** — `path: test`
- **files-specific** — `files: test/sample.lua`
- **annotate-warning** — Emit GitHub annotations

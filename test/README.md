# Tests

Documents each test in the [Luacheck workflow](../.github/workflows/luacheck.yml) and the equivalent action usage. Use these snippets with `uses: dekallo/luacheck@main` (or your fork).

## Fixtures

| File | Purpose |
|------|---------|
| `sample.lua` | Valid Lua (passes luacheck) |
| `bad.lua` | Invalid Lua (undefined variable — luacheck fails) |
| `validate.lua` | Test script: `--fail` (exit 1), `--echo a b c` (print args) |
| `write.lua` | Writes `test/.written-by-script` — scripts can modify repo |
| `luacheckrc.minimal` | Minimal config for remote-config tests |

---

## Execution modes

### Luacheck only

Luacheck on specific files, no custom script.

```yaml
- uses: dekallo/luacheck@main
  with:
    files: test/sample.lua
```

### Custom script only

Skip luacheck, run a Lua script.

```yaml
- uses: dekallo/luacheck@main
  with:
    run_luacheck: false
    custom_script: test/validate.lua
    custom_args: .
```

### Luacheck + custom script (both pass)

Run luacheck, then a script. Both must pass.

```yaml
- uses: dekallo/luacheck@main
  with:
    files: test/sample.lua
    custom_script: test/validate.lua
    custom_args: .
```

### Both disabled (no-op)

Neither luacheck nor script. Exits 0.

```yaml
- uses: dekallo/luacheck@main
  with:
    run_luacheck: false
```

---

## Failure modes

These fail the step (container exits non-zero). Use when you expect the action to fail.

### Luacheck fails

```yaml
- uses: dekallo/luacheck@main
  with:
    files: test/bad.lua
```

### Custom script fails

```yaml
- uses: dekallo/luacheck@main
  with:
    run_luacheck: false
    custom_script: test/validate.lua
    custom_args: --fail
```

### fail_fast: true — luacheck fails (script never runs)

Exits immediately on luacheck failure; script is skipped.

```yaml
- uses: dekallo/luacheck@main
  with:
    files: test/bad.lua
    fail_fast: true
    custom_script: test/validate.lua
    custom_args: .
```

### fail_fast: true — script fails

Exits immediately when script fails.

```yaml
- uses: dekallo/luacheck@main
  with:
    files: test/sample.lua
    fail_fast: true
    custom_script: test/validate.lua
    custom_args: --fail
```

### fail_fast: false — both run, luacheck fails

Runs both luacheck and script; fails at end because luacheck failed.

```yaml
- uses: dekallo/luacheck@main
  with:
    files: test/bad.lua
    fail_fast: false
    custom_script: test/validate.lua
    custom_args: .
```

### fail_fast: false — both run, script fails

Runs both; fails at end because script failed.

```yaml
- uses: dekallo/luacheck@main
  with:
    files: test/sample.lua
    fail_fast: false
    custom_script: test/validate.lua
    custom_args: --fail
```

---

## Input variations

### Config from URL

```yaml
- uses: dekallo/luacheck@main
  with:
    files: test/sample.lua
    config: https://raw.githubusercontent.com/your-org/your-repo/main/test/luacheckrc.minimal
```

### Luacheck args (-q)

```yaml
- uses: dekallo/luacheck@main
  with:
    files: test/sample.lua
    args: -q
```

### Custom script from URL

```yaml
- uses: dekallo/luacheck@main
  with:
    run_luacheck: false
    custom_script: https://raw.githubusercontent.com/your-org/your-repo/main/test/validate.lua
    custom_args: .
```

### Custom script with multiple args

```yaml
- uses: dekallo/luacheck@main
  with:
    run_luacheck: false
    custom_script: test/validate.lua
    custom_args: --echo foo bar
```

### Script modifies repo

Script writes `test/.written-by-script`. Add a follow-up step to verify.

```yaml
- uses: dekallo/luacheck@main
  with:
    run_luacheck: false
    custom_script: test/write.lua
- run: test -f test/.written-by-script
```

### Path subdirectory

Check files in a subdir. `path` sets working dir; `files` is relative to it.

```yaml
- uses: dekallo/luacheck@main
  with:
    path: test
    files: sample.lua
```

### Specific file

```yaml
- uses: dekallo/luacheck@main
  with:
    files: test/sample.lua
```

### Annotate warnings

Emit GitHub annotations for luacheck issues (shows in PR Files view).

```yaml
- uses: dekallo/luacheck@main
  with:
    files: test/bad.lua
    annotate: warning  # or "error"
```

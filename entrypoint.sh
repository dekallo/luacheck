#!/bin/sh
# luacheck GitHub Action entrypoint.
# Runs luacheck (optional) and/or a custom Lua script. Reads INPUT_* and GITHUB_WORKSPACE.
# Optional job summary when INPUT_JOB_SUMMARY=true and GITHUB_STEP_SUMMARY is set.
set -e

# --- Parse inputs (from env when used as GitHub Action) ---
FILES="${INPUT_FILES:-.}"
WORK_DIR="${GITHUB_WORKSPACE:-.}"
if [ -n "$INPUT_PATH" ] && [ "$INPUT_PATH" != "." ] && [ "$INPUT_PATH" != "$GITHUB_WORKSPACE" ]; then
    WORK_DIR="$WORK_DIR/$INPUT_PATH"
fi
ARGS="${INPUT_ARGS:-}"
CONFIG_URL="${INPUT_CONFIG:-}"
ANNOTATE="${INPUT_ANNOTATE:-none}"
CUSTOM_SCRIPT="${INPUT_CUSTOM_SCRIPT:-}"
CUSTOM_ARGS="${INPUT_CUSTOM_ARGS:-.}"
RUN_LUACHECK="${INPUT_RUN_LUACHECK:-true}"
FAIL_FAST="${INPUT_FAIL_FAST:-false}"
JOB_SUMMARY="${INPUT_JOB_SUMMARY:-false}"

luacheck_exit=0
script_exit=0
# Set to 1 when fail_fast exits after luacheck so summary does not show script as "passed".
EARLY_EXIT_NO_SCRIPT=0
# Temp files with command output for the job summary (removed on exit).
LUACHECK_OUTPUT_FILE=
SCRIPT_OUTPUT_FILE=

trap 'rm -f "$LUACHECK_OUTPUT_FILE" "$SCRIPT_OUTPUT_FILE"' EXIT

# Escape minimal HTML for safe <pre> in the job summary.
summary_pre_body() {
    sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' < "$1"
}

# --- Append Markdown to the workflow run summary (when available) ---
# https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#adding-a-job-summary
write_job_summary() {
    [ "$JOB_SUMMARY" = "true" ] || return 0
    [ -n "${GITHUB_STEP_SUMMARY:-}" ] || return 0
    # File may not exist in local docker runs
    if ! ( : >> "$GITHUB_STEP_SUMMARY" ) 2>/dev/null; then
        return 0
    fi
    {
        if [ "$RUN_LUACHECK" != "true" ] && [ -z "$CUSTOM_SCRIPT" ]; then
            return 0
        fi
        if [ "$RUN_LUACHECK" = "true" ]; then
            if [ "$luacheck_exit" -eq 0 ]; then
                echo "**Luacheck** — <span style=\"color:#1a7f37;font-weight:600\">passed</span>"
            else
                echo "**Luacheck** — <span style=\"color:#cf222e;font-weight:600\">failed</span>"
                if [ -n "$LUACHECK_OUTPUT_FILE" ] && [ -s "$LUACHECK_OUTPUT_FILE" ]; then
                    echo "<pre>"
                    summary_pre_body "$LUACHECK_OUTPUT_FILE"
                    echo "</pre>"
                fi
            fi
        fi
        if [ -n "$CUSTOM_SCRIPT" ]; then
            [ "$RUN_LUACHECK" = "true" ] && echo ""
            # Show basename for a shorter label when path is long.
            script_label="$CUSTOM_SCRIPT"
            case "$CUSTOM_SCRIPT" in
                */*) script_label=$(basename "$CUSTOM_SCRIPT") ;;
            esac
            if [ "$EARLY_EXIT_NO_SCRIPT" -eq 1 ]; then
                echo "**$script_label** — <span style=\"color:#656d76;font-style:italic\">skipped (fail-fast)</span>"
            elif [ "$script_exit" -eq 0 ]; then
                echo "**$script_label** — <span style=\"color:#1a7f37;font-weight:600\">passed</span>"
            else
                echo "**$script_label** — <span style=\"color:#cf222e;font-weight:600\">failed</span>"
                if [ -n "$SCRIPT_OUTPUT_FILE" ] && [ -s "$SCRIPT_OUTPUT_FILE" ]; then
                    echo "<pre>"
                    summary_pre_body "$SCRIPT_OUTPUT_FILE"
                    echo "</pre>"
                fi
            fi
        fi
    } >> "$GITHUB_STEP_SUMMARY" || true
}

# --- Setup: download config, change to working directory ---
setup() {
    if [ -n "$CONFIG_URL" ]; then
        mkdir -p ~/.config/luacheck
        if ! curl -fsSL "$CONFIG_URL" -o ~/.config/luacheck/.luacheckrc; then
            echo "::error::Unable to download config from \"$CONFIG_URL\"" >&2
            exit 1
        fi
    fi
    cd "$WORK_DIR"
}

# --- Annotate: convert luacheck output to GitHub workflow commands ---
annotate() {
    case "$ANNOTATE" in
        warning|error)
            awk -F':' -v level="$ANNOTATE" '
            BEGIN { blank = "" }
            /^[[:space:]]*$/ {
                blank = blank $0 "\n"
                next
            }
            /^[[:space:]]+.+:[0-9]+:[0-9]+:/ {
                blank = ""
                file = $1; gsub(/^[[:space:]]+/, "", file)
                line = $2; col = $3
                msg = $4
                for (i = 5; i <= NF; i++) msg = msg ":" $i
                gsub(/^[[:space:]]+/, "", msg)
                printf "::%s file=%s,line=%s,col=%s::%s:%s:%s: %s\n", level, file, line, col, file, line, col, msg
                next
            }
            {
                printf "%s", blank
                blank = ""
                print $0
            }
            END { printf "%s", blank }'
            ;;
        *)
            cat
            ;;
    esac
}

# --- Run luacheck ---
run_luacheck() {
    luacheck_exit=0
    if [ "$RUN_LUACHECK" = "true" ]; then
        echo "Running luacheck:"
        LUACHECK_OUTPUT_FILE=$(mktemp)
        set +e
        luacheck --no-cache $ARGS -- $FILES > "$LUACHECK_OUTPUT_FILE" 2>&1
        luacheck_exit=$?
        set -e
        annotate < "$LUACHECK_OUTPUT_FILE"
    fi
    return $luacheck_exit
}

# --- Run custom script when provided (URL or path) ---
run_custom_script() {
    script_exit=0
    if [ -n "$CUSTOM_SCRIPT" ]; then
        [ "$RUN_LUACHECK" = "true" ] && echo ""
        echo "Running $CUSTOM_SCRIPT:"
        script_path=""
        case "$CUSTOM_SCRIPT" in
            http://*|https://*)
                script_path="/tmp/script.lua"
                if ! curl -fsSL "$CUSTOM_SCRIPT" -o "$script_path"; then
                    echo "::error::Unable to download script from \"$CUSTOM_SCRIPT\"" >&2
                    exit 1
                fi
                ;;
            *)
                if [ -f "$CUSTOM_SCRIPT" ]; then
                    script_path="$CUSTOM_SCRIPT"
                elif [ -f "$WORK_DIR/$CUSTOM_SCRIPT" ]; then
                    script_path="$WORK_DIR/$CUSTOM_SCRIPT"
                else
                    echo "::error::Custom script not found: \"$CUSTOM_SCRIPT\"" >&2
                    exit 1
                fi
                ;;
        esac
        SCRIPT_OUTPUT_FILE=$(mktemp)
        set +e
        lua5.1 "$script_path" $CUSTOM_ARGS > "$SCRIPT_OUTPUT_FILE" 2>&1
        script_exit=$?
        set -e
        cat "$SCRIPT_OUTPUT_FILE"
        if [ $script_exit -ne 0 ]; then
            echo "::error::$CUSTOM_SCRIPT failed with exit code $script_exit" >&2
        fi
    fi
    return $script_exit
}

# --- Main ---
setup

set +e
run_luacheck
luacheck_exit=$?
set -e

if [ "$FAIL_FAST" = "true" ] && [ "$RUN_LUACHECK" = "true" ] && [ $luacheck_exit -ne 0 ]; then
    EARLY_EXIT_NO_SCRIPT=1
    write_job_summary
    exit $luacheck_exit
fi

set +e
run_custom_script
script_exit=$?
set -e

if [ "$FAIL_FAST" = "true" ] && [ -n "$CUSTOM_SCRIPT" ] && [ $script_exit -ne 0 ]; then
    write_job_summary
    exit $script_exit
fi

write_job_summary

if [ $luacheck_exit -ne 0 ] || [ $script_exit -ne 0 ]; then
    exit 1
fi
exit 0

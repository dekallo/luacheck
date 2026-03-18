#!/bin/sh
set -e

# Parse inputs (from env when used as GitHub Action)
FILES="${INPUT_FILES:-.}"
WORK_DIR="${GITHUB_WORKSPACE:-.}"
if [ -n "$INPUT_PATH" ] && [ "$INPUT_PATH" != "." ] && [ "$INPUT_PATH" != "$GITHUB_WORKSPACE" ]; then
    WORK_DIR="$WORK_DIR/$INPUT_PATH"
fi
ARGS="${INPUT_ARGS:-}"
CONFIG_URL="${INPUT_CONFIG:-}"
ANNOTATE="${INPUT_ANNOTATE:-none}"
TEST_SCRIPT="${INPUT_TEST_SCRIPT:-}"
TEST_ARGS="${INPUT_TEST_ARGS:-.}"
RUN_LUACHECK="${INPUT_RUN_LUACHECK:-true}"

# Download custom config if URL provided
if [ -n "$CONFIG_URL" ]; then
    mkdir -p ~/.config/luacheck
    if ! curl -fsSL "$CONFIG_URL" -o ~/.config/luacheck/.luacheckrc; then
        echo "::error::Unable to download config from \"$CONFIG_URL\"" >&2
        exit 1
    fi
fi

# Change to working directory (composite action sets GITHUB_WORKSPACE=/workspace)
cd "$WORK_DIR"

# Annotate function: parses luacheck output and emits GitHub workflow commands
# Luacheck format: "    path/to/file.lua:42:7: message"
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

# Run luacheck if enabled
exitcode=0
if [ "$RUN_LUACHECK" = "true" ]; then
    output=$(mktemp)
    trap 'rm -f "$output"' EXIT
    set +e
    luacheck --no-cache $ARGS -- $FILES > "$output" 2>&1
    exitcode=$?
    set -e
    annotate < "$output"
    if [ $exitcode -ne 0 ]; then
        exit $exitcode
    fi
fi

# Run test script when provided (URL or path)
if [ -n "$TEST_SCRIPT" ]; then
    script_path=""
    case "$TEST_SCRIPT" in
        http://*|https://*)
            script_path="/tmp/script.lua"
            if ! curl -fsSL "$TEST_SCRIPT" -o "$script_path"; then
                echo "::error::Unable to download script from \"$TEST_SCRIPT\"" >&2
                exit 1
            fi
            ;;
        *)
            if [ -f "$TEST_SCRIPT" ]; then
                script_path="$TEST_SCRIPT"
            elif [ -f "$WORK_DIR/$TEST_SCRIPT" ]; then
                script_path="$WORK_DIR/$TEST_SCRIPT"
            else
                echo "::error::Test script not found: \"$TEST_SCRIPT\"" >&2
                exit 1
            fi
            ;;
    esac
    set +e
    lua5.1 "$script_path" $TEST_ARGS
    exitcode=$?
    set -e
    if [ $exitcode -ne 0 ]; then
        echo "::error::$TEST_SCRIPT failed with exit code $exitcode" >&2
        exit $exitcode
    fi
fi

exit $exitcode

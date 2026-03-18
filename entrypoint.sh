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
CUSTOM_SCRIPT="${INPUT_CUSTOM_SCRIPT:-}"
CUSTOM_ARGS="${INPUT_CUSTOM_ARGS:-.}"
RUN_LUACHECK="${INPUT_RUN_LUACHECK:-true}"
FAIL_FAST="${INPUT_FAIL_FAST:-false}"

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
luacheck_exit=0
if [ "$RUN_LUACHECK" = "true" ]; then
    output=$(mktemp)
    trap 'rm -f "$output"' EXIT
    set +e
    luacheck --no-cache $ARGS -- $FILES > "$output" 2>&1
    luacheck_exit=$?
    set -e
    annotate < "$output"
    if [ "$FAIL_FAST" = "true" ] && [ $luacheck_exit -ne 0 ]; then
        exit $luacheck_exit
    fi
fi

# Run custom script when provided (URL or path)
script_exit=0
if [ -n "$CUSTOM_SCRIPT" ]; then
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
    set +e
    lua5.1 "$script_path" $CUSTOM_ARGS
    script_exit=$?
    set -e
    if [ $script_exit -ne 0 ]; then
        echo "::error::$CUSTOM_SCRIPT failed with exit code $script_exit" >&2
        if [ "$FAIL_FAST" = "true" ]; then
            exit $script_exit
        fi
    fi
fi

# Exit with failure if either failed
if [ $luacheck_exit -ne 0 ] || [ $script_exit -ne 0 ]; then
    exit 1
fi
exit 0

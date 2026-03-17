#!/bin/sh
set -e

# Parse inputs (from env when used as GitHub Action)
FILES="${INPUT_FILES:-.}"
WORK_DIR="${GITHUB_WORKSPACE:-.}"
ARGS="${INPUT_ARGS:-}"
CONFIG_URL="${INPUT_CONFIG:-}"
ANNOTATE="${INPUT_ANNOTATE:-none}"

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
            { print $0 }
            /^[[:space:]]+.+:[0-9]+:[0-9]+:/ {
                file = $1
                gsub(/^[[:space:]]+/, "", file)
                line = $2
                col = $3
                msg = $4
                gsub(/^[[:space:]]+/, "", msg)
                printf "::%s file=%s,line=%s,col=%s::%s\n", level, file, line, col, msg
            }'
            ;;
        *)
            cat
            ;;
    esac
}

# Run luacheck (--no-cache for CI reproducibility)
output=$(mktemp)
trap 'rm -f "$output"' EXIT
luacheck --no-cache $ARGS -- $FILES > "$output" 2>&1
exitcode=$?

# Emit output to stdout (host captures and re-prints so it's visible on failure)
echo "::group::Luacheck output"
annotate < "$output"
echo "::endgroup::"

exit $exitcode

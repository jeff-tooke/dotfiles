#!/usr/bin/env bash

# Max depth of path segments to show after ~ or root
MAX_DEPTH=3

# Get the current path
CURRENT_PATH="$1"

# --- Handle being exactly in HOME ---
if [[ "$CURRENT_PATH" == "$HOME" ]]; then
    echo "~"
    exit 0 # Exit early if in home directory
fi

# --- Handle paths within HOME ---
if [[ "$CURRENT_PATH" == "$HOME/"* ]]; then # Note the '/' here
    RELATIVE_PATH="~/${CURRENT_PATH#$HOME/}"
# --- Handle paths outside HOME ---
else
    RELATIVE_PATH="$CURRENT_PATH"
fi

# Split the path into segments
# Handle the case where RELATIVE_PATH might just be "/" (root)
if [[ "$RELATIVE_PATH" == "/" ]]; then
    echo "/"
    exit 0
fi

IFS='/' read -r -a PATH_SEGMENTS <<< "$RELATIVE_PATH"

# Remove any empty elements that might arise from leading/trailing slashes
# e.g., "//a/b" could result in empty first element
PATH_SEGMENTS=( "${PATH_SEGMENTS[@]///}" ) # Remove empty strings

# Ensure the first element is "~" or the actual root "/" for paths outside HOME
if [[ "$RELATIVE_PATH" == "~"* && "${PATH_SEGMENTS[0]}" != "~" ]]; then
    PATH_SEGMENTS=("~" "${PATH_SEGMENTS[@]}")
elif [[ "$RELATIVE_PATH" == "/*" && "${PATH_SEGMENTS[0]}" != "" && "${RELATIVE_PATH:0:1}" == "/" && "${PATH_SEGMENTS[0]}" != "/" ]]; then
    # For paths like /usr/local, the split might be [usr, local]
    # We need to explicitly add the leading slash back for non-home paths
    PATH_SEGMENTS=("/" "${PATH_SEGMENTS[@]}")
fi


# If the path is too long, shorten it
if (( ${#PATH_SEGMENTS[@]} > MAX_DEPTH + 1 )); then # +1 for the leading ~ or /
    # Construct the shortened path, keeping the beginning and the last few segments
    SHORTENED_PATH_ARRAY=("${PATH_SEGMENTS[0]}" "...")
    for (( i=${#PATH_SEGMENTS[@]}-MAX_DEPTH; i<${#PATH_SEGMENTS[@]}; i++ )); do
        SHORTENED_PATH_ARRAY+=("${PATH_SEGMENTS[i]}")
    done
    echo "$(IFS='/'; echo "${SHORTENED_PATH_ARRAY[*]}")"
else
    # Reconstruct the path for display, handling initial "~" or "/"
    if [[ "${PATH_SEGMENTS[0]}" == "~" ]]; then
        # Join segments with / and remove any leading / if it was added
        echo "$(IFS='/'; echo "${PATH_SEGMENTS[*]}")" | sed 's#^/\~#\~#'
    elif [[ "${PATH_SEGMENTS[0]}" == "/" ]]; then
        # Join segments with /
        echo "$(IFS='/'; echo "${PATH_SEGMENTS[*]}")" | sed 's#^/#/#' # Ensure single leading slash
    else
        echo "$(IFS='/'; echo "${PATH_SEGMENTS[*]}")" # Fallback for odd cases
    fi
fi

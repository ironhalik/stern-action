# This code is meant to be used with
# https://github.com/ironhalik/kubectl-action-base
if [ ! -n "${IS_KUBECTL_ACTION_BASE}" ]; then
    echo "::error:: The script is not meant to be used on it's own."
    exit 1
fi

# kubectl-action specific code
STERN_ARGS=""
[ -n "${INPUT_SEARCH_TERM}" ] && STERN_ARGS="${STERN_ARGS} ${INPUT_SEARCH_TERM}"
[ -n "${INPUT_NAMESPACE}" ] && STERN_ARGS="${STERN_ARGS} --namespace ${INPUT_NAMESPACE}"
[ -n "${INPUT_SELECTOR}" ] && STERN_ARGS="${STERN_ARGS} --selector ${INPUT_SELECTOR}"
[ -n "${INPUT_SINCE}" ] && STERN_ARGS="${STERN_ARGS} --since ${INPUT_SINCE}"

if [ -n "${INPUT_UNTIL}" ]; then
    echo "Running: stern ${STERN_ARGS}, looking for string \"${INPUT_UNTIL}\". Will timeout after ${INPUT_TIMEOUT}."
    set +e
    trap "" PIPE
    timeout "${INPUT_TIMEOUT}" stern ${STERN_ARGS} 2>&1 | sed "/${INPUT_UNTIL}/q"
    status_codes=("${PIPESTATUS[@]}")
    if [ "${status_codes[0]}" -eq 143 ]; then
        echo "Timed out while waiting for \"${INPUT_UNTIL}\"."
        exit 2
    elif [ "${status_codes[1]}" -eq 0 ]; then
        echo "\"${INPUT_UNTIL}\" found."
        exit 0
    else
        exit "$((status_codes[0] + status_codes[1]))"
    fi
else
    echo "Running: stern ${STERN_ARGS}. Will timeout after ${INPUT_TIMEOUT}."
    set +e
    timeout "${INPUT_TIMEOUT}" stern ${STERN_ARGS}
    if [ "${status_code}" -eq 143 ]; then
        echo "Timed out, as expected."
        exit 0
    else
        exit ${status_code}
    fi
fi

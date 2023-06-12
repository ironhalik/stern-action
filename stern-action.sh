# shellcheck shell=bash
# This code is meant to be used with
# https://github.com/ironhalik/kubectl-action-base
if [ -z "${IS_KUBECTL_ACTION_BASE}" ]; then
    echo "::error:: The script is not meant to be used on it's own."
    exit 1
fi

# kubectl-action specific code
get_inputs SEARCH_TERM SELECTOR SINCE UNTIL TIMEOUT

STERN_ARGS=""
[ -n "${SEARCH_TERM}" ] && STERN_ARGS="${STERN_ARGS} ${SEARCH_TERM}"
[ -n "${SELECTOR}" ] && STERN_ARGS="${STERN_ARGS} --selector ${SELECTOR}"
[ -n "${SINCE}" ] && STERN_ARGS="${STERN_ARGS} --since ${SINCE}"

if [ -n "${UNTIL}" ]; then
    echo "Running: stern ${STERN_ARGS}, looking for string \"${UNTIL}\". Will timeout after ${TIMEOUT}."

    set +e
    # shellcheck disable=SC2086
    timeout "${TIMEOUT}" sed "/${UNTIL}/q" < <(stern ${STERN_ARGS} 2>&1)
    status=${?}
    pkill stern

    if [ "${status}" -eq 143 ]; then
        echo "Timed out while waiting for \"${UNTIL}\"."
        exit 2
    elif [ "${status}" -eq 0 ]; then
        echo "\"${UNTIL}\" found."
        exit 0
    else
        echo "Something weird happened."
        exit "${status}"
    fi
else
    echo "Running: stern ${STERN_ARGS}. Will timeout after ${TIMEOUT}."
    set +e
    # shellcheck disable=SC2086
    timeout "${TIMEOUT}" stern ${STERN_ARGS}
    status_code="${?}"
    if [ "${status_code}" -eq 143 ]; then
        echo "Timed out, as expected."
        exit 0
    else
        exit "${status_code}"
    fi
fi

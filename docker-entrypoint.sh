#!/bin/bash
set -e
set -o pipefail

[ -n "${INPUT_DEBUG}" ] && RUNNER_DEBUG=1

log_debug() {
    echo -e "${*}" | sed 's/^/::debug:: /g'
}

if [ -n "${INPUT_CONFIG}" ]; then
    if [[ "${INPUT_CONFIG}" =~ ^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)?$ ]]; then
        log_debug "Looks like config is in base64. Decoding."
        echo "${INPUT_CONFIG}" | base64 -d > /tmp/config
    else
        log_debug "Looks like config is plain yaml. Using it like it."
        echo "${INPUT_CONFIG}" > /tmp/config
    fi
elif [ -n "${INPUT_EKS_CLUSTER}" ]; then
    log_debug "Using AWS CLI to get the cluster config..."
    aws_output=$(aws eks update-kubeconfig --name "${INPUT_EKS_CLUSTER}")
    log_debug "${aws_output}"
else
    echo "::error:: Either config or eks_cluster must be specified."
    exit 1
fi
if [ -n "${INPUT_CONTEXT}" ]; then
    kubectl config set-context "${INPUT_CONTEXT}"
fi
log_debug "Current kubectl context: $(kubectl config current-context)"

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

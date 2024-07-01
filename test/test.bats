# shellcheck disable=SC2030,SC2031
setup() {
    load 'lib/bats-support/load'
    load 'lib/bats-assert/load'

    export INPUT_DEBUG=true
    export INPUT_SEARCH_TERM="." # action default
    export INPUT_SINCE="5m" # action default
    export INPUT_TIMEOUT="1s"
    export INPUT_CONFIG="YXBpVmVyc2lvbjogdjEKY2x1c3RlcnM6Ci0gY2x1c3RlcjoKICAgIHNlcnZlcjogaHR0cDovL2V4YW1wbGUuY29tCiAgbmFtZTogdGVzdC1jbHVzdGVyCmNvbnRleHRzOgotIGNvbnRleHQ6CiAgICBjbHVzdGVyOiB0ZXN0LWNsdXN0ZXIKICAgIG5hbWVzcGFjZTogZGVmYXVsdAogICAgdXNlcjogdGVzdC11c2VyCiAgbmFtZTogdGVzdC1jb250ZXh0Ci0gY29udGV4dDoKICAgIGNsdXN0ZXI6ICIiCiAgICB1c2VyOiAiIgogIG5hbWU6IHRoZS1vdGhlci1jb250ZXh0CmN1cnJlbnQtY29udGV4dDogdGVzdC1jb250ZXh0CmtpbmQ6IENvbmZpZwpwcmVmZXJlbmNlczoge30KdXNlcnM6Ci0gbmFtZTogdGVzdC11c2VyCiAgdXNlcjoKICAgIHRva2VuOiB0ZXN0LXRva2VuCg=="

    DIR="$(cd "$( dirname "${BATS_TEST_FILENAME}" )" > /dev/null 2>&1 && pwd)"
    PATH="${DIR}/../:${PATH}"
}

teardown() {
    echo "" > /kubeconfig
}

@test "running with defaults" {
    run kubectl-action.sh
    assert_output --partial "Running: stern  . --since 5m."
    assert_output --partial "Not Found"
    assert_success
}

@test "custom search term" {
    export INPUT_SEARCH_TERM="some-dep-name"
    run kubectl-action.sh
    assert_output --partial "Running: stern  some-dep-name --since 5m."
    assert_success
}

@test "custom search term (using env var)" {
    unset INPUT_SEARCH_TERM
    export SEARCH_TERM="some-dep-name"
    run kubectl-action.sh
    assert_output --partial "Running: stern  some-dep-name --since 5m."
    assert_success
}

@test "custom since" {
    export INPUT_SINCE="60s"
    run kubectl-action.sh
    assert_output --partial "Running: stern  . --since 60s."
    assert_success
}

@test "string not found" {
    export INPUT_UNTIL="app started"
    run kubectl-action.sh
    assert_output --partial "looking for string \"app started\""
    assert_output --partial "Timed out while waiting"
    assert_failure
}

@test "string found" {
    export START="${SECONDS}"
    export INPUT_UNTIL="Not Found"
    export INPUT_TIMEOUT="30s"
    run kubectl-action.sh
    if [ $((SECONDS - START)) -gt "10" ]; then
        fail 'Took too long.'
    fi
    assert_output --partial "\"could not find the requested resource\" found."
    assert_success
}

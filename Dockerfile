FROM ghcr.io/ironhalik/kubectl-action-base:v1.0

COPY stern-action.sh /usr/local/bin/docker-entrypoint.d/

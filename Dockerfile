FROM ghcr.io/ironhalik/kubectl-action:v1.0

COPY stern-action.sh /usr/local/bin/kubectl-action.d/

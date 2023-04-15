FROM ghcr.io/ironhalik/kubectl-action:v1.2

COPY stern-action.sh /usr/local/bin/kubectl-action.d/

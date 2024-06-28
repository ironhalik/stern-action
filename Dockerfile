FROM ghcr.io/ironhalik/kubectl-action:v1.4

COPY stern-action.sh /usr/local/bin/kubectl-action.d/

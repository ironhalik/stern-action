An action providing kubernetes log tailing.

----
### Example usage:
```
steps:
# Will tail logs of all pods with name app, labeled with current commit.
# Once "Application started." string is found, will successfully exit.
- name: Tail logs
  uses: ironhalik/stern-action@v1
  with:
    config: ${{ secrets.CONFIG }} # base64 encoded or neat
    search-term: app
    namespace: my-awesome-app
    selector: commit==${{ github.sha }}
    until: "Application started."
```

Supported inputs are: 
- `debug` can be enabled explicitly via action input, or is implicitly enabled when a job is rerun with debug enabled. Will make kubectl and related scripts verbose.
- `config` kubectl config file. Can be either a whole config file (e.g. via ${{ secrets.CONFIG }}), or base64 encoded.
- `eks_cluster` The name of the EKS cluster to get config for. Will use AWS CLI to generate a valid config. Will need standard `aws-cli` env vars and eks:DescribeCluster permission. Mutually exclusive with `config`.
- `context` kubectl config context to use. Not needed if the config has a context already selected.
- `eks_role_arn` IAM role ARN that should be assumed by `aws-cli` when interacting with EKS cluster.
- `namespace` namespace to use. You can use env vars here.
- `search-term` what pods to tail.
- `selector` kubectl selector to use for tailing pods.
- `since` since when should we tail logs.
- `until` will stop tailing when it finds the sepcified string.
- `timeout` how long to try tailing for.

Many thanks to the creators of the tools included:  
[kubectl](https://github.com/kubernetes/kubectl), [helm](https://github.com/helm/helm), [stern](https://github.com/wercker/stern), [aws-cli](https://github.com/aws/aws-cli)
# Security

## Enforced controls

| Control | What it does | Gotcha |
|---|---|---|
| Restricted Pod Security Standard | `restricted` is the cluster default; can be overriden in namespace. | Violating pods are **silently rejected** — check `kubectl -n <ns> events`. |
| Trivy scan (CI) | Scans charts for misconfigurations (trusted registries, network policies, `securityContext`, …). | Blocks at the PR gate, not at deploy. Helm **replaces** (not merges) `securityContext`, so each chart must repeat the full block. |
| Mandatory resource limits | Admission policy denies pods whose containers lack cpu+memory limits. | Includes init & ephemeral containers. Can be skipped via a speical label. |
| Default-deny network policy | Denies all ingress/egress (except DNS) cluster-wide. | All apps must explicitly define network connections they need via Network Policies |

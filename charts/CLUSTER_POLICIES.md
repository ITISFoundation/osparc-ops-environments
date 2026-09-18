# Security

## Enforced controls

| Control | What it does | Gotcha |
|---|---|---|
| Restricted Pod Security Standard | `restricted` is the cluster default; can be overriden in namespace. | Violating pods are **silently rejected** — check `kubectl -n <ns> events`. |
| Trivy scan (CI) | Scans charts for misconfigurations (trusted registries, network policies, `securityContext`, …). | Added as a CI test for Pull Requests |
| Mandatory resource limits | Admission policy denies pods whose containers lack cpu+memory limits. | Pods not respecting this policy would be rejected. Includes init & ephemeral containers. Can be skipped via a special label. |
| Default-deny network policy | Denies all ingress/egress (except DNS) cluster-wide. | All apps must explicitly define network connections they need via Network Policies |

# Security

This file documents security measures and their configuration in current code base

## Application developer

Full list: https://kubernetes.io/docs/concepts/security/application-security-checklist/

#### Pod-level securityContext recommendations

Enable pod security standard on namespace level:
* create namespace with labels (examples and explanations https://aro-labs.com/pod-security-standards/)
* configure pod and container security context to satisfy security standards (read more https://medium.com/dynatrace-engineering/kubernetes-security-part-3-security-context-7d44862c4cfa)

## Cluster / OPS developers

Full list: https://kubernetes.io/docs/concepts/security/security-checklist/

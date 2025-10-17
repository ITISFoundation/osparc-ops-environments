## Network policy

Read more https://cert-manager.io/docs/installation/best-practice/#network-requirements

Be aware that this might have an affect on cert manager webhook application that is called during installation of the cert manager helm chart. If network policy is misconfigured, this will affect installation (e.g. `certissuers` might be missing as they are installed via helm hooks that apparently require cert manager webhook to be reachable)

## Extract certificate from secret

```bash
kubectl -n <namespace> get secret <secret-tls> -o jsonpath="{.data['tls\.crt']}" | base64 -d | openssl x509 -text -noout | head
```

# Traefik

## Known issues
On traefik restart often the errors logs about missing middleware can be observed. This is apparently a race condition that is a false-positive since afterwards traefik works and all routers are healthy. See this issue comment https://github.com/traefik/traefik/issues/9779#issuecomment-5240603731

```
2026-08-10T12:57:06Z ERR error="middleware \"traefik-basic-auth@kubernetescrd\" does not exist" entryPointName=websecure routerName=traefik-traefik-dashboard-monitoring-k8s-osparc-local-dashboard@kubernetes
```

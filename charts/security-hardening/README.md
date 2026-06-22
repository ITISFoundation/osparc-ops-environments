## How to add network policy (local deployment)

How to discover ports / networks that are used by application
* observe existing traffic (see `Debug network policies` below)
* add staged policies to make sure all cases are included https://docs.tigera.io/calico/3.30/network-policy/staged-network-policies
  - make sure deployed calico version supports it
* based on observations, create a needed network policy

## Debug network policies

if calico version 3.30+ is installed
* observe traffic and check `policies` field in whisker logs
  - https://docs.tigera.io/calico/3.30/observability/enable-whisker
  - https://docs.tigera.io/calico/3.30/observability/view-flow-logs

if calico version <= 3.29
* create network policy with action log (read more https://docs.tigera.io/calico/latest/network-policy/policy-rules/log-rules)
* WARNING: these logs are shown in journalctl **of the node where restricted workload (POD / Container) is running**
  ```yaml
  apiVersion: projectcalico.org/v3
  kind: NetworkPolicy
  metadata:
    name: log ingress requests
  spec:
    selector: app == 'db'
    ingress:
    - action: Log
  ```
* apply policy and see logs via journalctl (you can grep with `calico-packet` on the node where the pod is running)
* Note: one may implement policy step by step (allowing all traffic that is known and making last rule `Log` to see what traffic is still missing)

## Known issues

If network policy is created after pod, pod **MUST** be restarted for policy to take effect. Read more https://github.com/projectcalico/calico/issues/10753#issuecomment-3140717418
* To automate this, we can add annotations with network policy checksum to pods (see https://stackoverflow.com/questions/58602311/will-helm-upgrade-restart-pods-even-if-they-are-not-affected-by-upgrade)

## How to view existing policies

via kubectl:
* `kubectl get networkpolicies.crd.projectcalico.org -n adminer`
* `kubectl describe networkpolicies.crd.projectcalico.org -n adminer default.adminer-network-policy`

via calicoctl:
* `calicoctl get networkpolicy -n adminer -o yaml`

Note:
* global network policies and network policies are separate resources for calico
* To see all calico resources execute `kubectl get crd | grep calico` or `calicoctl get --help`

Warning:
* Network policies update are only applied to "new connections". To make them act, one may need to restart affected applications (pods)

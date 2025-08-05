## How to add network policy (local deployment)

How to discover ports / networks that are used by application
* enable and observe traffic via
  - https://docs.tigera.io/calico/3.30/observability/enable-whisker
  - https://docs.tigera.io/calico/3.30/observability/view-flow-logs
* add staged policies to make sure all cases are included https://docs.tigera.io/calico/3.30/network-policy/staged-network-policies
* transform staged policies to "normal" policies

## Debug network policies
* observe traffic and check `policies` field in whisker logs
  - https://docs.tigera.io/calico/3.30/observability/enable-whisker
  - https://docs.tigera.io/calico/3.30/observability/view-flow-logs

Warning: make sure that calico version being used support Whisker (e.g. in v3.26 whisker is not documented at all)

## Known issues

If network policy is created after pod, pod **MUST** be restarted for policy to take effect. Read more https://github.com/projectcalico/calico/issues/10753#issuecomment-3140717418

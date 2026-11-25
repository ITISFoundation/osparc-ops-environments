A CI Deployment directory reflecting a real deployment directory structure with stub values.

This is only used for static code analysis. It cannot be used to run real workloads as some
of them contradict (e.g. having both topolvm and aws-ebs-csi-driver charts that both create
default storage class)

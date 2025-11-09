enable-flow-logs:
	kubectl apply -f flowlogs.yaml
	kubectl port-forward -n calico-system service/whisker 8081:8081

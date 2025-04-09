create:
	kind create cluster --name crossplane-localstack-lab
	./bootstrap.sh

destroy:
	kind delete cluster --name crossplane-localstack-lab

apply:
	kubectl apply -f manifests/

status:
	kubectl get all -n crossplane-system
	kubectl get bucket,queue,restapis,function,role || true

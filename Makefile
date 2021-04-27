CLUSTER ?= services
REGION ?= ap-south-1
CTX ?= $(shell kubectl config current-context)

init:
	@aws ec2 describe-subnets --query  "Subnets[?Tags[?Key == 'Name' && contains(Value, 'App')][]].SubnetArn" | jq -r '.[]' | xargs -I {} aws resourcegroupstaggingapi   tag-resources --resource-arn-list {} --tags kubernetes.io/role/internal-elb=1
	@aws ec2 describe-subnets --query  "Subnets[?Tags[?Key == 'Name' && contains(Value, 'App')][]].SubnetArn" | jq -r '.[]' | xargs -I {} aws resourcegroupstaggingapi   tag-resources --resource-arn-list {} --tags kubernetes.io/cluster/$(CLUSTER)=shared
	@aws ec2 describe-subnets --query  "Subnets[?Tags[?Key == 'Name' && contains(Value, 'Web')][]].SubnetArn" | jq -r '.[]' | xargs -I {} aws resourcegroupstaggingapi   tag-resources --resource-arn-list {} --tags kubernetes.io/role/elb=1
	@aws ec2 describe-subnets --query  "Subnets[?Tags[?Key == 'Name' && contains(Value, 'Web')][]].SubnetArn" | jq -r '.[]' | xargs -I {} aws resourcegroupstaggingapi   tag-resources --resource-arn-list {} --tags kubernetes.io/cluster/$(CLUSTER)=shared

create:
#	@eksctl --region $(REGION) create cluster --config-file=clusters/$(CLUSTER_NAME)/cluster.yaml
	@eksctl upgrade cluster --config-file=clusters/$(CLUSTER)/$(REGION)/cluster.yaml --approve

dump:
	@eksctl utils write-kubeconfig --cluster services

addons:
	@eksctl utils update-kube-proxy --config-file=clusters/$(CLUSTER)/$(REGION)/cluster.yaml --approve
	@eksctl utils update-aws-node --config-file=clusters/$(CLUSTER)/$(REGION)/cluster.yaml --approve
	@eksctl utils update-coredns --config-file=clusters/$(CLUSTER)/$(REGION)/cluster.yaml --approve

coredns:
	kubectl patch deployment coredns \
        -n kube-system \
        --type json \
        -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
	kubectl  patch deployment coredns \
		-n kube-system \
		-p='{"spec":{"template":{"spec":{"containers":[{ "name": "coredns","resources":{"limits":{"cpu":"250m","memory":"256Mi"},"requests":{"cpu":"250m","memory":"256Mi"}}}]}}}}'
	kubectl annotate deployment coredns \
		-n kube-system downscaler/downtime-replicas-

ng:
	@eksctl create nodegroup --config-file=clusters/$(CLUSTER)/$(REGION)/cluster.yaml
	@eksctl delete nodegroup --config-file=clusters/$(CLUSTER)/$(REGION)/cluster.yaml --only-missing

sa:
	@eksctl create iamserviceaccount --config-file=clusters/$(CLUSTER)/$(REGION)/cluster.yaml --approve --override-existing-serviceaccounts

identity:
#	@eksctl create iamidentitymapping --cluster $(CLUSTER) --service-name emr-containers --namespace default
	eksctl --region $(REGION) create iamidentitymapping --cluster $(CLUSTER) --group system:masters  --username iam:{{SessionName}} --arn $$(aws iam list-roles  --query 'Roles[?starts_with(RoleName, `AWSReservedSSO_AWSPowerUserAccess`) == `true`].Arn' --output text |  awk -F'/' '{ print $$1 "/" $$4}')

flux:
	@flux bootstrap github \
		  --context=$(CTX)  \
		  --owner=nslhb \
		  --repository=services.nslhub.com \
		  --branch=main \
		  --path=clusters/$(CLUSTER)/$(REGION) \
		  --toleration-keys=CriticalAddonsOnly \
		  --components-extra=image-reflector-controller,image-automation-controller

flux/source:
	@flux create source git infra \
         --url=ssh://git@github.com/nslhb/gitops-devops.git \
         --branch=main

cleanup:
	@kubectl delete mutatingwebhookconfigurations  kube-prometheus-stack-admission
	@kubectl delete ValidatingWebhookConfiguration kube-prometheus-stack-admission
	@kubectl delete mutatingwebhookconfigurations  linkerd-proxy-injector-webhook-config
	@kubectl delete apiservice v1beta1.custom.metrics.k8s.io  v1beta1.metrics.k8s.io  v1beta1.external.metrics.k8s.io
	@kubectl delete apiservice v2beta1.helm.toolkit.fluxcd.io v1beta1.kustomize.toolkit.fluxcd.io

echo:
	@echo "cluster $(CLUSTER) in $(REGION) with context $(CTX)"

dns:
	
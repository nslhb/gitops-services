CLUSTER ?= services
REGION ?= ap-south-1
CTX ?= $(shell kubectl config current-context)
NS ?= "istio-system linkerd-viz argo-rollouts monitoring observability logging apps paas taas tf"

echo:
	@echo "cluster $(CLUSTER) in $(REGION) with context $(CTX)"

subnet:
	@aws ec2 describe-subnets --region $(REGION) --query  "Subnets[?Tags[?Key == 'Name' && contains(Value, 'App')][]].SubnetArn" | jq -r '.[]' | xargs -I {} aws resourcegroupstaggingapi   tag-resources  --region $(REGION) --resource-arn-list {} --tags kubernetes.io/role/internal-elb=1
	@aws ec2 describe-subnets --region $(REGION) --query  "Subnets[?Tags[?Key == 'Name' && contains(Value, 'App')][]].SubnetArn" | jq -r '.[]' | xargs -I {} aws resourcegroupstaggingapi   tag-resources  --region $(REGION) --resource-arn-list {} --tags kubernetes.io/cluster/$(CLUSTER)=shared
	@aws ec2 describe-subnets --region $(REGION) --query  "Subnets[?Tags[?Key == 'Name' && contains(Value, 'Web')][]].SubnetArn" | jq -r '.[]' | xargs -I {} aws resourcegroupstaggingapi   tag-resources  --region $(REGION) --resource-arn-list {} --tags kubernetes.io/role/elb=1
	@aws ec2 describe-subnets --region $(REGION) --query  "Subnets[?Tags[?Key == 'Name' && contains(Value, 'Web')][]].SubnetArn" | jq -r '.[]' | xargs -I {} aws resourcegroupstaggingapi   tag-resources  --region $(REGION) --resource-arn-list {} --tags kubernetes.io/cluster/$(CLUSTER)=shared

cluster:
	if eksctl get cluster --name $(CLUSTER) --region $(REGION) -o json > /dev/null 2>&1 ; then \
  	eksctl upgrade cluster --config-file=clusters/$(CLUSTER)/$(REGION)/cluster.yaml --approve; else \
  	eksctl create cluster --config-file=clusters/$(CLUSTER)/$(REGION)/cluster.yaml; fi

ep:
	eksctl utils update-cluster-endpoints -f clusters/$(CLUSTER)/$(REGION)/cluster.yaml --approve


config:
	@eksctl utils write-kubeconfig --cluster $(CLUSTER) --region $(REGION)

ng:
	@eksctl --skip-outdated-addons-check=true create nodegroup --config-file=clusters/$(CLUSTER)/$(REGION)/cluster.yaml
	@eksctl delete nodegroup --config-file=clusters/$(CLUSTER)/$(REGION)/cluster.yaml --only-missing --approve

sa:
	@eksctl create iamserviceaccount --config-file=clusters/$(CLUSTER)/$(REGION)/cluster.yaml --approve --override-existing-serviceaccounts
	@eksctl update iamserviceaccount --config-file=clusters/$(CLUSTER)/$(REGION)/cluster.yaml --approve
	@eksctl delete iamserviceaccount --config-file=clusters/$(CLUSTER)/$(REGION)/cluster.yaml --approve --only-missing

fg:
	@eksctl create fargateprofile --config-file=clusters/$(CLUSTER)/$(REGION)/cluster.yaml
	@eksctl delete fargateprofile --config-file=clusters/$(CLUSTER)/$(REGION)/cluster.yaml --only-missing --approve

identity:
	eksctl --region $(REGION) create iamidentitymapping --cluster $(CLUSTER) --group system:masters  --username iam:{{SessionName}} --arn $$(aws iam list-roles  --query 'Roles[?starts_with(RoleName, `AWSReservedSSO_AWSPowerUserAccess`) == `true`].Arn' --output text |  awk -F'/' '{ print $$1 "/" $$4}')
	eksctl --region $(REGION) create iamidentitymapping --cluster $(CLUSTER) --group view  --username iam:{{SessionName}} --arn $$(aws iam list-roles  --query 'Roles[?starts_with(RoleName, `AWSReservedSSO_AWSReadOnlyAccess`) == `true`].Arn' --output text |  awk -F'/' '{ print $$1 "/" $$4}')

flux:
	@eksctl enable flux -f clusters/$(CLUSTER)/$(REGION)/cluster.yaml

cleanup:
	@kubectl delete mutatingwebhookconfigurations  kube-prometheus-stack-admission
	@kubectl delete ValidatingWebhookConfiguration kube-prometheus-stack-admission
	@kubectl delete mutatingwebhookconfigurations  linkerd-proxy-injector-webhook-config
	@kubectl delete apiservice v1beta1.custom.metrics.k8s.io  v1beta1.metrics.k8s.io  v1beta1.external.metrics.k8s.io
	@kubectl delete apiservice v2beta1.helm.toolkit.fluxcd.io v1beta1.kustomize.toolkit.fluxcd.io

down:
	flux suspend ks tenants
	for nss in $(NS); do \
  	    kubectl annotate ns $$nss downscaler/force-uptime- ; \
  		kubectl annotate ns $$nss downscaler/uptime='Mon-Fri 08:30-08:30 Asia/Kolkata'; done

up:
	for nss in $(NS); do \
  	    kubectl annotate ns $$nss downscaler/uptime- ; \
		kubectl annotate ns $$nss downscaler/force-uptime=true; done
	flux resume ks tenants

auto:
	for nss in $$(kubectl get ns | awk '{print $$1}'); do \
		kubectl annotate ns $$nss downscaler/uptime- ; \
		kubectl annotate ns $$nss downscaler/force-uptime-; done

eks: echo subnet cluster ng sa identity

coredns:
	kubectl patch deployment coredns -n kube-system --type json \
        -p='[{"op": "add", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
	#kubectl annotate deployment coredns -n kube-system downscaler/downtime-replicas-

ci:
	kubectl create secret docker-registry regcred --docker-server=https://index.docker.io/v1/ --docker-username=$$(DOCKER_USER) --docker-password=$$(DOCKER_PASSWORD) --docker-email=$$(DOCKER_EMAIL)

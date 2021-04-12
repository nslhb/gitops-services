init:
	@aws ec2 describe-subnets --query  "Subnets[?Tags[?Key == 'Name' && contains(Value, 'App')][]].SubnetArn" | jq -r '.[]' | xargs -I {} aws resourcegroupstaggingapi   tag-resources --resource-arn-list {} --tags kubernetes.io/role/internal-elb=1
	@aws ec2 describe-subnets --query  "Subnets[?Tags[?Key == 'Name' && contains(Value, 'App')][]].SubnetArn" | jq -r '.[]' | xargs -I {} aws resourcegroupstaggingapi   tag-resources --resource-arn-list {} --tags kubernetes.io/cluster/services=shared
	@aws ec2 describe-subnets --query  "Subnets[?Tags[?Key == 'Name' && contains(Value, 'Web')][]].SubnetArn" | jq -r '.[]' | xargs -I {} aws resourcegroupstaggingapi   tag-resources --resource-arn-list {} --tags kubernetes.io/role/elb=1
	@aws ec2 describe-subnets --query  "Subnets[?Tags[?Key == 'Name' && contains(Value, 'Web')][]].SubnetArn" | jq -r '.[]' | xargs -I {} aws resourcegroupstaggingapi   tag-resources --resource-arn-list {} --tags kubernetes.io/cluster/services=shared

create:
	@eksctl create cluster --config-file=infrastructure/cluster.yaml

coredns:
	kubectl patch deployment coredns \
        -n kube-system \
        --type json \
        -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
	kubectl patch deployment coredns \
		-n kube-system \
		-p='{"spec":{"template":{"spec":{"containers":[{ "name": "coredns","resources":{"limits":{"cpu":"250m","memory":"256Mi"},"requests":{"cpu":"250m","memory":"256Mi"}}}]}}}}'

ng:
	@eksctl create nodegroup --config-file=cluster/cluster.yaml

upgrade:
	@eksctl upgrade cluster --config-file=cluster/cluster.yaml --approve
	@eksctl delete nodegroup --config-file=cluster/cluster.yaml --only-missing
	@eksctl utils update-kube-proxy --config-file=infrastructure/cluster.yaml --approve
	@eksctl utils update-aws-node --config-file=infrastructure/cluster.yaml --approve
	@eksctl utils update-coredns --config-file=infrastructure/cluster.yaml --approve

dump:
	@eksctl utils write-kubeconfig --cluster services

flux:
	@flux bootstrap github \
         --context=dc  \
         --owner=nslhb \
         --repository=services.nslhub.com \
         --branch=main \
         --path=clusters/services-us-east-1 \
         --toleration-keys=SystemAddonsOnly \
         --components-extra=image-reflector-controller,image-automation-controller
	@flux bootstrap github \
		  --context=mum  \
		  --owner=nslhb \
		  --repository=services.nslhub.com \
		  --branch=main \
		  --path=clusters/services-ap-south-1 \
		   --toleration-keys=SystemAddonsOnly \
		   --components-extra=image-reflector-controller,image-automation-controller
cleanup:
	kubectl delete mutatingwebhookconfigurations.admissionregistration.k8s.io kube-prometheus-stack-admission   linkerd-proxy-injector-webhook-config
	kubectl delete apiservice v1beta1.custom.metrics.k8s.io  v1beta1.metrics.k8s.io

init/apsouth1:
	@make init
	@make create
init:
	@aws ec2 describe-subnets --query  "Subnets[?Tags[?Key == 'Name' && contains(Value, 'App')][]].SubnetArn" | jq -r '.[]' | xargs -I {} aws resourcegroupstaggingapi   tag-resources --resource-arn-list {} --tags kubernetes.io/role/internal-elb=1
	@aws ec2 describe-subnets --query  "Subnets[?Tags[?Key == 'Name' && contains(Value, 'App')][]].SubnetArn" | jq -r '.[]' | xargs -I {} aws resourcegroupstaggingapi   tag-resources --resource-arn-list {} --tags kubernetes.io/cluster/services=shared
	@aws ec2 describe-subnets --query  "Subnets[?Tags[?Key == 'Name' && contains(Value, 'Web')][]].SubnetArn" | jq -r '.[]' | xargs -I {} aws resourcegroupstaggingapi   tag-resources --resource-arn-list {} --tags kubernetes.io/role/elb=1
	@aws ec2 describe-subnets --query  "Subnets[?Tags[?Key == 'Name' && contains(Value, 'Web')][]].SubnetArn" | jq -r '.[]' | xargs -I {} aws resourcegroupstaggingapi   tag-resources --resource-arn-list {} --tags kubernetes.io/cluster/services=shared

create:
	@eksctl create cluster --config-file=infrastructure/cluster.yaml

upgrade:
	@eksctl upgrade cluster --config-file=cluster/cluster.yaml --approve
	@eksctl create nodegroup --config-file=cluster/cluster.yaml
	@eksctl delete nodegroup --config-file=cluster/cluster.yaml --only-missing

addons:
	@eksctl utils update-kube-proxy --config-file=infrastructure/cluster.yaml --approve
	@eksctl utils update-aws-node --config-file=infrastructure/cluster.yaml --approve
	@eksctl utils update-coredns --config-file=infrastructure/cluster.yaml --approve

dump:
	@eksctl utils write-kubeconfig --cluster services

flux:
	@flux bootstrap github \
         --context=rohit.verma@nslhub.com@services.us-east-1.eksctl.io  \
         --owner=nslhb \
         --repository=services.nslhub.com \
         --branch=main \
         --path=clusters/services-us-east-1
	@flux bootstrap github \
			  --context=rohit.verma@nslhub.com@services.ap-south-1.eksctl.io  \
			  --owner=nslhb \
			  --repository=services.nslhub.com \
			  --branch=main \
			  --path=clusters/services-ap-south-1

init/apsouth1:
	@make init
	@make create
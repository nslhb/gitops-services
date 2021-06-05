# Adding a new cluster

1. Start with adding cluster.yaml and do eksctl create. Note this is a manual step for now till we figure out a way for eks reconciliation, 1 good option is to use github runners.
2. Once eksctl is run, it will also bootstrap flux on the cluster.
3. We need to add github secrets for all the git repos manually. 
4. Add kyverno and tenants sync files, copy from other cluster's, it will be same. TODO try to apply DRY
5. There are multiple teams, each team has to provide the configuration what branch/tag of their repo they want to run on the cluster. May need to create new branch
6. Devops is currently not based on branch but base on dir. This would be soon switch to profiles.
7. For terraform recon, we need to create secrets in secret manager [ devops/kube-system/tfcloud, devops/kube-system/workspace ]
.

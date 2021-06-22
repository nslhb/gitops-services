#!/bin/bash

export SVC_ACT="hyperglance-user"
export NAMESPACE="default"
export KUBECFG_FILE_NAME="./hyperglance-kubeconfig.conf"
export TARGET_FOLDER="test"

create_target_folder() {
  echo -n "Creating target directory to hold files in ${TARGET_FOLDER}..."
  mkdir -p "${TARGET_FOLDER}"
  printf "done"
}

create_service_account() {
  echo -e "\\nCreating a service account: ${SVC_ACT}"
  kubectl create sa "${SVC_ACT}" --namespace "${NAMESPACE}"
}

get_secret_name_from_service_account() {
  echo -e "\\nGetting secret of service account ${SVC_ACT}-${NAMESPACE}"
  SECRET_NAME=$(kubectl get sa "${SVC_ACT}" --namespace "${NAMESPACE}" -o json | jq -r '.secrets[].name')
  echo "Secret name: ${SECRET_NAME}"
}

extract_ca_crt_from_secret() {
  echo -e -n "\\nExtracting ca.crt from secret..."
  kubectl get secret "${SECRET_NAME}" --namespace "${NAMESPACE}" -o json | jq \
  -r '.data["ca.crt"]' | base64 -d > "${TARGET_FOLDER}/ca.crt"
  printf "done"
}

get_user_token_from_secret() {
  echo -e -n "\\nGetting user token from secret..."
  USER_TOKEN=$(kubectl get secret "${SECRET_NAME}" \
  --namespace "${NAMESPACE}" -o json | jq -r '.data["token"]' | base64 -d)
  printf "done"
}

set_kube_config_values() {
  context=$(kubectl config current-context)
  echo -e "\\nSetting current context to: $context"

  CLUSTER_NAME=$(kubectl config get-contexts "$context" | awk '{print $3}' | tail -n 1)
  echo "Cluster name: ${CLUSTER_NAME}"

  ENDPOINT=$(kubectl config view \
  -o jsonpath="{.clusters[?(@.name == \"${CLUSTER_NAME}\")].cluster.server}")
  echo "Endpoint: ${ENDPOINT}"

  # Set up the config
  echo -e "\\nPreparing k8s-${SVC_ACT}-${NAMESPACE}-conf"
  echo -n "Start a new entry in kubeconfig"
  kubectl config set-cluster "${CLUSTER_NAME}" \
  --kubeconfig="${KUBECFG_FILE_NAME}" \
  --server="${ENDPOINT}" \
  --certificate-authority="${TARGET_FOLDER}/ca.crt" \
  --embed-certs=true

  echo -n "Add tokens to Kubeconfig - the Hyperglance API will use this to access your cluster resources."
  kubectl config set-credentials \
  "${SVC_ACT}-${NAMESPACE}-${CLUSTER_NAME}" \
  --kubeconfig="${KUBECFG_FILE_NAME}" \
  --token="${USER_TOKEN}"

  echo -n "Add context entry to kubeconfig, this will be used by hyperglance."
  kubectl config set-context \
  "${SVC_ACT}-${NAMESPACE}-${CLUSTER_NAME}" \
  --kubeconfig="${KUBECFG_FILE_NAME}" \
  --cluster="${CLUSTER_NAME}" \
  --user="${SVC_ACT}-${NAMESPACE}-${CLUSTER_NAME}" \
  --namespace="${NAMESPACE}"
}

create_cluster_role() {
cat <<EOF | kubectl apply -f -
  apiVersion: rbac.authorization.k8s.io/v1
  kind: ClusterRole
  metadata:
    name: hyperglance-cluster-role
  rules:
  -
    apiGroups:
      - ""
      - apps
      - autoscaling
      - batch
      - extensions
      - policy
      - rbac.authorization.k8s.io
    resources:
      - componentstatuses
      - configmaps
      - daemonsets
      - deployments
      - events
      - endpoints
      - horizontalpodautoscalers
      - ingresses
      - jobs
      - limitranges
      - namespaces
      - nodes
      - pods
      - persistentvolumes
      - persistentvolumeclaims
      - resourcequotas
      - replicasets
      - replicationcontrollers
      - serviceaccounts
      - services
    verbs:
      - get
      - watch
      - list
  - nonResourceURLs: ["*"]
    verbs:
      - get
      - watch
      - list
EOF
}

create_cluster_role_binding() {
  cat <<EOF | kubectl apply -f -
  apiVersion: rbac.authorization.k8s.io/v1beta1
  kind: ClusterRoleBinding
  metadata:
    name: hyperglance-cluster-role-binding
  roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: hyperglance-cluster-role
  subjects:
  - kind: ServiceAccount
    name: ${SVC_ACT}
    namespace: default
EOF
}

create_target_folder
create_service_account
get_secret_name_from_service_account
extract_ca_crt_from_secret
get_user_token_from_secret
set_kube_config_values

echo -e "Now Creating RBAC permissions with your current Kubeconfig"
create_cluster_role
create_cluster_role_binding

echo -n "Now, you can copy the newly generated Kubeconfig file to Hyperglance.  It is called ${KUBECFG_FILE_NAME}"
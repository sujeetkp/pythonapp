#!/bin/bash

CLUSTER_NAME=""
AWS_REGION="us-east-2"

aws eks update-kubeconfig \
  --region $AWS_REGION \
  --name $CLUSTER_NAME

export KUBECONFIG="~/.kube/config"
echo $KUBECONFIG

kubectl get nodes

# Uninstall helm charts:
helm uninstall pythonapp
helm uninstall external-dns
helm uninstall cert-manager
helm uninstall nginx-ingress

# Delete Policy and Roles
ROLE_NAME="cert-manager"
POLICY_ARN=$(aws iam list-attached-role-policies --role-name $ROLE_NAME | jq .AttachedPolicies[0].PolicyArn | sed s/\"//g)
aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn $POLICY_ARN
aws iam delete-role --role-name $ROLE_NAME

ROLE_NAME="external-dns"
POLICY_ARN=$(aws iam list-attached-role-policies --role-name $ROLE_NAME | jq .AttachedPolicies[0].PolicyArn | sed s/\"//g)
aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn $POLICY_ARN
aws iam delete-role --role-name $ROLE_NAME

aws iam delete-policy --policy-arn $POLICY_ARN

# Destroy  EKS Cluster
terraform -chdir=terraform-eks-cluster-deploy destroy -input=false -var-file=config.tfvars -auto-approve

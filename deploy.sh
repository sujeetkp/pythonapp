#!/bin/bash

#AWS Credentials must be Present as Environmental Variables
#export AWS_ACCESS_KEY_ID=""
#export AWS_SECRET_ACCESS_KEY=""
export AWS_DEFAULT_REGION="us-west-2"

#jq and wget must be installed
sudo yum install epel-release -y 
sudo yum update -y
sudo yum install -y jq
sudo yum install -y wget
sudo yum install -y unzip

# Install Terraform
TERRAFORM_VERSION="1.0.0"
tf_version=$TERRAFORM_VERSION
sudo wget https://releases.hashicorp.com/terraform/"$TERRAFORM_VERSION"/terraform_"$TERRAFORM_VERSION"_linux_amd64.zip
sudo unzip terraform_"$TERRAFORM_VERSION"_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version

#######################################

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version

#######################################

# Install aws-iam-authenticator
curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/aws-iam-authenticator
sudo mv aws-iam-authenticator /usr/local/bin/
sudo chmod +x /usr/local/bin/aws-iam-authenticator
aws-iam-authenticator version

#######################################

# Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
sudo chmod 700 get_helm.sh
sudo ./get_helm.sh
helm version

sleep 5

################################################

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

#######################################

# Deploy EKS Cluster
terraform -chdir=terraform-eks-cluster-deploy init -input=false -backend-config=backend.conf
terraform -chdir=terraform-eks-cluster-deploy validate
terraform -chdir=terraform-eks-cluster-deploy plan -input=false -lock=false -var-file=config.tfvars
exit
terraform -chdir=terraform-eks-cluster-deploy apply -input=false -var-file=config.tfvars -auto-approve

sleep 5

#######################################

# Define Kubecofig Location
export KUBECONFIG=./terraform-eks-cluster-deploy/kubeconfig/kubeconfig
echo $KUBECONFIG

kubectl get nodes

#######################################

# Get OIDC details
PROVIDER_ARN=$(terraform -chdir=terraform-eks-cluster-deploy output -json | jq -r .oidc_provider_arn.value)
ISSUER_HOSTPATH=$(terraform -chdir=terraform-eks-cluster-deploy output -json | jq -r .oidc_provider_arn.value |  awk -F 'provider/' '{print $2}')

echo $PROVIDER_ARN
echo $ISSUER_HOSTPATH

#######################################

# Install Nginx Ingress
# By default Nginx-Ingress creates a Classic Load Balancer.
# You must override the annotation to create a NLB
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install nginx-ingress ingress-nginx/ingress-nginx -f ./nginx-ingress-controller/values.yml

sleep 300  #It takes some time for the NLB to come up.

###########################################################
# Install cert-manager 
# Service Account for cert-manager
SERVICE_ACCOUNT_NAMESPACE='cert-manager'
SERVICE_ACCOUNT_NAME='cert-manager'
ROLE_NAME='cert-manager'
POLICY_NAME='AllowExternalDNSUpdates'

echo $SERVICE_ACCOUNT_NAMESPACE
echo $SERVICE_ACCOUNT_NAME
echo $ROLE_NAME
echo $POLICY_NAME

# Cert Manager Assume Role Policy
cat > ./cert-manager-config/assume-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "$PROVIDER_ARN"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${ISSUER_HOSTPATH}:sub": "system:serviceaccount:${SERVICE_ACCOUNT_NAMESPACE}:${SERVICE_ACCOUNT_NAME}"
        }
      }
    }
  ]
}
EOF

cat ./cert-manager-config/assume-policy.json

# Create Policy
aws iam create-policy --policy-name $POLICY_NAME --policy-document file://cert-manager-config/iam-policies.json > /tmp/policy.json
POLICY_ARN=$(cat /tmp/policy.json | jq -r .Policy.Arn)
echo $POLICY_ARN

# Create Role
#aws iam update-assume-role-policy --role-name $ROLE_NAME --policy-document file://cert-manager-config/assume-policy.json
aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://cert-manager-config/assume-policy.json
ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query Role.Arn --output text)
echo $ROLE_ARN

# Attach Policy to Role
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn $POLICY_ARN

# Override values in values.yml for cert-manager helm chart
# This is done to map the AWS IAM Role to the cert-manager Service Account
cat > ./cert-manager-config/custom-values.yml << EOF
securityContext:
  enabled: "true"
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: $ROLE_ARN
EOF

cat ./cert-manager-config/custom-values.yml

# Install cert-manager
kubectl create namespace cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm template cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --set installCRDs=true \
  -f ${PWD}/cert-manager-config/custom-values.yml | kubectl apply -f -

sleep 5

#####################################################
# Install external-dns 
# "external-dns" looks for any ingress creation and creates AWS Route53
# DNS entries for the hosts mentioned in the ingress.
# Alias records are created pointing to the Load Balancer

# Service Account for external-dns
SERVICE_ACCOUNT_NAMESPACE='default'
SERVICE_ACCOUNT_NAME='external-dns'
ROLE_NAME='external-dns'
POLICY_NAME='AllowExternalDNSUpdates'

echo $SERVICE_ACCOUNT_NAMESPACE
echo $SERVICE_ACCOUNT_NAME
echo $ROLE_NAME
echo $POLICY_NAME

# Cert Manager Assume Role Policy
cat > ./external-dns-config/assume-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "$PROVIDER_ARN"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${ISSUER_HOSTPATH}:sub": "system:serviceaccount:${SERVICE_ACCOUNT_NAMESPACE}:${SERVICE_ACCOUNT_NAME}"
        }
      }
    }
  ]
}
EOF

cat ./external-dns-config/assume-policy.json

# Create Role
aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://external-dns-config/assume-policy.json
ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query Role.Arn --output text)
echo $ROLE_ARN

# Attach Policy to Role
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn $POLICY_ARN

# AWS Hosted Zone Details
HOSTED_ZONE_NAME='summitailabs.xyz'
HOSTED_ZONE_ID='Z0348607Q5LAXWIYWIN0'

echo $HOSTED_ZONE_NAME
echo $HOSTED_ZONE_ID

# Install external dns
helm repo add bitnami https://charts.bitnami.com/bitnami

helm install external-dns bitnami/external-dns \
--set provider=aws \
--set domainFilters[0]=${HOSTED_ZONE_NAME} \
--set policy=sync \
--set registry=txt \
--set txtOwnerId=${HOSTED_ZONE_ID} \
--set aws.zoneType=public \
--set interval=3m \
--set rbac.create=true \
--set serviceAccount.name=external-dns \
--set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$ROLE_ARN

sleep 5

#####################################################

# Create Secret
kubectl create secret generic secretdata \
--from-literal secretkey=c580aba8fd78d73fe3bf804dbf433e95  \
--from-literal emailpassword=suj.cap-430002  \
--from-literal dbpassword=postgres

#####################################################

# Install Application
helm install pythonapp --debug --dry-run blog-chart/
helm install pythonapp ./blog-chart/
echo 'App Installed Successfully'

#######################################
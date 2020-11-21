#!/bin/sh

# AWS region environment variables
export AWS_DEFAULT_REGION=eu-west-1
export AWS_REGION=eu-west-1

# EKS cluster name environment variables
export AWS_CLUSTER_NAME=mlplatform
export CLUSTER_NAME=mlplatform


# Route 53 subdomain name environment variable (REPLACE domain.com WITH YOUR OWN DOMAIN)
export DOMAIN_NAME=*.platform.domain.com


# ACM certificate environment variable
export ACM_CERT_ARN=$(aws acm list-certificates --region $AWS_REGION \
                --query CertificateSummaryList[].[CertificateArn,DomainName] \
                --output text | grep $DOMAIN_NAME | cut -f1)


# Cognito environment variabes
export COGNITO_STACK_NAME=mlplatform-cognito-stack

# REPLACE domain.com WITH YOUR OWN DOMAIN
export COGNITO_USER_POOL_DOMAIN=auth.platform.domain.com

# Retrieves the Cognito user pool name from the CloudFormation stack output
export COGNITO_USER_POOL=$(aws cloudformation describe-stacks --stack-name $COGNITO_STACK_NAME \
                --region $AWS_REGION \
                --query "Stacks[0].Outputs[?OutputKey=='UserPool'].OutputValue" \
                --output text)

# Retrieves the Cognito app client id from the CloudFormation stack output
export COGNITO_APP_CLIENT_ID=$(aws cloudformation describe-stacks --stack-name $COGNITO_STACK_NAME \
                --region $AWS_REGION \
                --query "Stacks[0].Outputs[?OutputKey=='UserPoolClientId'].OutputValue" \
                --output text)

# Retrieves the Cognito user pool id from the CloudFormation stack output
export COGNITO_USER_POOL_ID=$(aws cloudformation describe-stacks --stack-name $COGNITO_STACK_NAME \
                --region $AWS_REGION \
                --query "Stacks[0].Outputs[?OutputKey=='UserPoolId'].OutputValue" \
                --output text)

# Retrieves the Cognito user pool ARN from the aws cli by passing the user pool id as an argument
export COGNITO_USER_POOL_ARN=$(aws cognito-idp describe-user-pool --user-pool-id $COGNITO_USER_POOL_ID \
                --region $AWS_REGION \
                --query UserPool.Arn \
                --output text)


# EKS cluster node role environment variable retrieved using the aws cli and jq
export AWS_CLUSTER_NODE_ROLE=$(aws iam list-roles \
                | jq -r ".Roles[] \
                | select(.RoleName \
                | startswith(\"eksctl-$AWS_CLUSTER_NAME\") and contains(\"NodeInstanceRole\")) \
                .RoleName")

# Adds the environment variables and dynamically generates the kubeflow manifest file
cat << EOF > kubeflow_manifest.yaml
apiVersion: kfdef.apps.kubeflow.org/v1
kind: KfDef
metadata:
  namespace: kubeflow
spec:
  applications:
  - kustomizeConfig:
      repoRef:
        name: manifests
        path: namespaces/base
    name: namespaces
  - kustomizeConfig:
      repoRef:
        name: manifests
        path: stacks/aws/application/istio-stack
    name: istio-stack
  - kustomizeConfig:
      repoRef:
        name: manifests
        path: stacks/aws/application/cluster-local-gateway
    name: cluster-local-gateway
  - kustomizeConfig:
      repoRef:
        name: manifests
        path: stacks/aws/application/istio
    name: istio
  - kustomizeConfig:
      repoRef:
        name: manifests
        path: application/v3
    name: application
  - kustomizeConfig:
      repoRef:
        name: manifests
        path: stacks/aws/application/cert-manager-crds
    name: cert-manager-crds
  - kustomizeConfig:
      repoRef:
        name: manifests
        path: stacks/aws/application/cert-manager-kube-system-resources
    name: cert-manager-kube-system-resources
  - kustomizeConfig:
      repoRef:
        name: manifests
        path: stacks/aws/application/cert-manager
    name: cert-manager
  - kustomizeConfig:
      repoRef:
        name: manifests
        path: metacontroller/base
    name: metacontroller
  - kustomizeConfig:
      repoRef:
        name: manifests
        path: admission-webhook/bootstrap/overlays/application
    name: bootstrap
  - kustomizeConfig:
      repoRef:
        name: manifests
        path: spark/spark-operator/overlays/application
    name: spark-operator
  - kustomizeConfig:
      repoRef:
        name: manifests
        path: knative/installs/generic
    name: knative
  - kustomizeConfig:
      repoRef:
        name: manifests
        path: kfserving/installs/generic
    name: kfserving
  - kustomizeConfig:
      repoRef:
        name: manifests
        path: stacks/aws/application/spartakus
    name: spartakus
  - kustomizeConfig:
      repoRef:
        name: manifests
        path: tensorboard/overlays/istio
    name: tensorboard
  - kustomizeConfig:
      repoRef:
        name: manifests
        path: stacks/aws
    name: kubeflow-apps
  - kustomizeConfig:
      repoRef:
        name: manifests
        path: stacks/aws/application/istio-ingress-cognito
    name: istio-ingress
  - kustomizeConfig:
      repoRef:
        name: manifests
        path: aws/aws-istio-authz-adaptor/base_v3
    name: aws-istio-authz-adaptor
  plugins:
  - kind: KfAwsPlugin
    metadata:
      name: aws
    spec:
      auth:
        cognito:
          certArn: ${ACM_CERT_ARN}
          cognitoAppClientId: ${COGNITO_APP_CLIENT_ID}
          cognitoUserPoolArn: ${COGNITO_USER_POOL_ARN}
          cognitoUserPoolDomain: ${COGNITO_USER_POOL_DOMAIN}
      region: ${AWS_REGION}
      roles:
      - ${AWS_CLUSTER_NODE_ROLE}
  repos:
  - name: manifests
    uri: https://github.com/kubeflow/manifests/archive/v1.1-branch.tar.gz
  version: v1.1-branch
EOF

# Builds and creates Kubeflow on the EKS cluster
# kfctl build -f kubeflow_manifest.yaml -V
# kfctl apply -f kubeflow_manifest.yaml -V
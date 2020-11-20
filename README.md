# Kubeflow with Cognito on EKS
The following project demonstrates the process of deploying a secure implementation of Kubeflow on top of a Kubernetes cluster provided by Amazon's Elastic Kubernetes Service (EKS). The Kubeflow deployment is secured using an application load balancer (ALB), Route 53 and Amazon Cognito.

## Prerequisites
- [AWS access key ID and secret access key](https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-started_create-delegated-user.html)
- jq (1.6)
- awscli (v1.18.179)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl) (v1.19.4)
- [eksctl](https://eksctl.io) (v0.31.0)
- [aws-iam-authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html) (v0.5.2)
- [kfctl](https://github.com/kubeflow/kfctl/releases/tag/v1.1.0) (v1.1.0-0-g9a3621e)

This project assumes that you already have a domain registered through Amazon Route 53 so that subdomains can be easily created and managed. If not, this [guide](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-register.html) demonstrates the process.

## 1. EKS Cluster Creation
Before creating the EKS cluster make sure that the Kubernetes config file generated by AWS is empty. This can be achieved by deleting it as follows:
``` 
rm -rf /Users/<your-name>/.kube/config 
```

The EKS cluster can then be created by running:
``` 
eksctl create cluster -f eks_cluster.yaml 
```

## 2. Cognito User Pool Creation
The Cognito user pool can be created via the `cognito.yaml` CloudFormation template by running the following AWS CLI command:
```
aws cloudformation create-stack \
    --stack-name "mlplatform-cognito-stack" \
    --template-body file://cognito.yaml \
    --capabilities CAPABILITY_IAM \
    --parameters ParameterKey=UserPoolName,ParameterValue=mlplatform \
    --region eu-west-1
```

This will provision the Cognito user pool that will be used to authenticate Kubeflow users.

## 3. Kubeflow Deployment
This Kubeflow deployment uses the following [manifest](https://raw.githubusercontent.com/kubeflow/manifests/v1.1-branch/kfdef/kfctl_aws_cognito.v1.1.0.yaml) as a base. The kubeflow manifest file is defined dynamically using environment variables inside the `mlplatform/` directory. It is recommended to deploy Kubeflow inside a folder that shares the EKS cluster name. If you want to change the cluster name, make sure to update the `mlplatform/` directory and the `CLUSTER_NAME` environment variable.

Make sure to replace `domain.com` with your own domain name in the appropriate environment variables before proceeding. Kubeflow can be deployed on the cluster by running the following command:
```
sh deploy_kubeflow.sh
```

This deployment should take a few minutes and once ready the ALB should have a status of `active` in the AWS console. This means that Route 53 can now be updated and the domain can front the load balancer.

## Resource Cleanup
At this time I have found the easiest way to delete Kubeflow and the EKS cluster is by deleting the CloudFormation stacks in the AWS Console.

The node instance role may need to be deleted in a separate action. Any EBS volumes that have been created should also be deleted.

The artifacts generated by the kfctl `build` and `apply` commands can be deleted by running `sh clean_mlplatform.sh` in the root directory.

## Additional Resources
- [jq download](https://stedolan.github.io/jq/download/)
- [Kubeflow Overview](https://www.kubeflow.org/docs/about/kubeflow/)
- [Kubeflow on EKS with Cognito](https://www.kubeflow.org/docs/aws/aws-e2e/)
- [Kubeflow and Cognito](https://devopstar.com/2020/03/31/kubeflow-on-eks-cognito-authentication)
- [Cognito deployment using CloudFormation](https://gist.github.com/singledigit/2c4d7232fa96d9e98a3de89cf6ebe7a5)
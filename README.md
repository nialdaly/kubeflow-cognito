# Kubeflow with Cognito on EKS
The following project demonstrates the process of deploying a secure implementation of Kubeflow on Amazon Elastic Kubernetes Service (EKS). Kubeflow is secured using Amazon Cognito.

## Prerequisites
- awscli (v1.18.179)
- eksctl (v0.31.0)
- kfctl (v1.1.0-0-g9a3621e)

This project assumes that you already have a domain registered through Amazon Route 53.

## EKS Cluster Creation
Before creating the EKS cluster make sure that the Kubernetes config file generated by AWS is empty. This can be achieved by deleting it as follows:
``` 
rm -rf /Users/<your-name>/.kube/config 
```

The EKS cluster can then be created by running:
``` 
eksctl create cluster -f eks_cluster.yaml 
```

## Cognito User Pool Creation
The Cognito User Pool can be created via the `cognito.yaml` CloudFormation template by running the following AWS CLI command:
```
aws cloudformation create-stack \
    --stack-name "mlplatform-cognito-stack" \
    --template-body file://cognito.yaml \
    --capabilities CAPABILITY_IAM \
    --parameters ParameterKey=UserPoolName,ParameterValue=mlplatform \
    --region eu-west-1
```

This will provision the Cognito user pool that will be used to authenticate Kubeflow users.

## Resource Cleanup
At this time I have found the easiest way to delete Kubeflow and the EKS cluster is by deleting the CloudFormation stacks in the AWS Console.

The node instance role may need to be deleted in a separate action. Any EBS volumes that have been created should also be deleted.

The artifacts generated by the kfctl `build` and `apply` commands can be deleted by running `sh clean_mlplatform.sh` in the root directory.

## Additional Resources
- [Kubeflow on EKS with Cognito](https://www.kubeflow.org/docs/aws/aws-e2e/)

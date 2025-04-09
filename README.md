# Crossplane Localstack

## Setup

```bash
sh bootstrap.sh

kubectl get bucket
kubectl get queue
kubectl get instance

awslocal s3 ls
awslocal sqs list-queues

awslocal ec2 describe-instances

awslocal ec2 run-instances \   
  --image-id ami-12345678 \
  --instance-type t2.micro
```

## Lambda & API Gateway

```bash
awslocal s3 mb s3://crossplane-test-bucket
awslocal s3 cp lambda/demo-lambda.zip s3://crossplane-test-bucket/demo-lambda.zip

kubectl apply -f manifests/

kubectl get all -n crossplane-system
kubectl get function,role,restapi,resource,method,integration,deployment


API_ID=$(awslocal apigateway get-rest-apis --query 'items[?name==`demo-api`].id' --output text)
curl http://localhost:4566/restapis/$API_ID/test/_user_request_/demo

```

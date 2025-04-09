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

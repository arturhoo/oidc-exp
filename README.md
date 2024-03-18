
## Prerequisites

Working environment for AWS and GCloud CLIs. For GCP, the setup of Application Default Credentials is also required:

```
$ gcloud auth application-default login
```

## Environment Variables

```
$ export GCP_PROJECT_ID=$(gcloud config get-value project)
$ export GCP_REGION=<to_be_defined>
$ export GCP_ZONE=<to_be_defined>
$ export S3_BUCKET=<to_be_defined>
$ export GCS_BUCKET=<to_be_defined>
```

## Terraform

```
$ terraform apply \
    -var 'project_id=$GCP_PROJECT_ID' \
    -var 'region=$GCP_REGION' \
    -var 'zone=$GCP_ZONE' \
    -var 's3_bucket=$S3_BUCKET' \
    -var 'gcs_bucket=$GCS_BUCKET' \
    -var 'aws_region=$AWS_REGION' \
    -var 'aws_profile=$AWS_PROFILE'
```

## Kubernetes on GKE

```
$ export PROJECT_ID=$(gcloud config get-value project)
$ envsubst < kubernetes/gke/serviceaccount.yaml | kubectl apply -f -
$ kubectl apply -f kubernetes/gke/pod.yaml
```

```
$ k exec -it aws-cli -- bash
bash-4.2# AWS_WEB_IDENTITY_TOKEN_FILE=/var/run/secrets/tokens/oidc-exp-service-account-token AWS_ROLE_ARN=arn:aws:iam::$account_od:role/oidc_exp_federated_role aws s3 ls s3://$s3_bucket
2024-03-17 18:29:42         15 test.txt
```

## Kubernetes on EKS

```
$ export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
$ envsubst < kubernetes/eks/serviceaccount.yaml | kubectl apply -f -
$ kubectl apply -f kubernetes/eks/pod.yaml
```

```
$ k exec -it aws-cli -- bash
bash-4.2# aws s3 ls s3://$s3_bucket
2024-03-17 18:29:42         15 test.txt
```
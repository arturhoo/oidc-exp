
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

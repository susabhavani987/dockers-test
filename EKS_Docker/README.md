
# EKS + PySpark Sample Project

Run a containerized PySpark job on **Amazon EKS** that writes Parquet output to **Amazon S3**.

## Repo Layout
- `app.py` — sample PySpark job (filters sample data and writes to S3)
- `Dockerfile` — builds a Spark + PySpark runtime
- `k8s/namespace.yaml` — creates `data-jobs` namespace
- `k8s/serviceaccount.yaml` — service account annotated for IRSA (recommended)
- `k8s/configmap.yaml` — non-sensitive config (S3 bucket, region)
- `k8s/pyspark-job.yaml` — Kubernetes Job that runs the container
- `.github/workflows/deploy-pyspark-eks.yml` — CI/CD to build/push image & apply manifests

## Prereqs
- An EKS cluster (e.g., `my-eks-cluster`) and `kubectl` access
- An S3 bucket (e.g., `your-s3-bucket-name`) in your region
- **Recommended**: IRSA (IAM Roles for Service Accounts) granting S3 write access
- **Optional (dev only)**: A Kubernetes Secret with AWS keys

## Configure
1. Edit `k8s/configmap.yaml`:
   ```yaml
   data:
     S3_BUCKET: your-s3-bucket-name
     OUTPUT_PREFIX: eks-pyspark-output
     AWS_REGION: us-east-2
   ```
2. (IRSA) Update `k8s/serviceaccount.yaml` with your IAM role ARN that allows S3 access:
   ```yaml
   annotations:
     eks.amazonaws.com/role-arn: arn:aws:iam::<ACCOUNT_ID>:role/<ROLE_NAME>
   ```
3. (Optional) If not using IRSA (dev only), create a Secret with AWS keys:
   ```bash
   kubectl -n data-jobs create secret generic aws-credentials \
     --from-literal=aws_access_key_id=AKIA... \
     --from-literal=aws_secret_access_key=xxxxxxxx
   ```

## GitHub Actions Secrets
Set these in your repo Settings → Secrets and variables → Actions:
- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- (Optional) `IRSA_ROLE_ARN`

## CI/CD
- Push to `main`:
  - Builds and pushes Docker image to Docker Hub
  - Updates kubeconfig for your EKS cluster
  - Applies namespace, configmap, serviceaccount, and Job

## Manual Apply (alternative to CI)
```bash
docker build -t <docker-user>/pyspark-eks:latest .
docker push <docker-user>/pyspark-eks:latest

# Replace image in manifest
sed -i "s|my-dockerhub-user/pyspark-eks:latest|<docker-user>/pyspark-eks:latest|g" k8s/pyspark-job.yaml

kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/serviceaccount.yaml
kubectl apply -f k8s/pyspark-job.yaml
```

## Run Output
The job writes Parquet files to: `s3://<your-bucket>/eks-pyspark-output/`

## Clean Up
```bash
kubectl -n data-jobs delete job pyspark-job
kubectl delete -f k8s/
```

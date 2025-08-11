name: Build Image → Push Docker Hub → Terraform Deploy

on:
  push:
    branches: [ main ]

env:
  TF_WORKING_DIR: ./terraform

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up QEMU (for multi-platform, optional)
        uses: docker/setup-qemu-action@v2

      - name: Log in to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build Docker image
        run: |
          IMAGE_TAG=${GITHUB_SHA::8}
          IMAGE=${{ secrets.DOCKER_USERNAME }}/python-docker-app:${IMAGE_TAG}
          echo "IMAGE=${IMAGE}" >> $GITHUB_ENV
          docker build -t ${IMAGE} .

      - name: Push Docker image to Docker Hub
        run: |
          docker push $IMAGE

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION || 'us-east-1' }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.5

      - name: Terraform Init
        working-directory: ${{ env.TF_WORKING_DIR }}
        run: terraform init -input=false

      - name: Terraform Plan
        working-directory: ${{ env.TF_WORKING_DIR }}
        run: terraform plan -input=false -var="image=${IMAGE}"

      - name: Terraform Apply
        working-directory: ${{ env.TF_WORKING_DIR }}
        run: terraform apply -auto-approve -input=false -var="image=${IMAGE}"

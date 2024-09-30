#!/bin/bash

# Check if environment argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <environment>"
  exit 1
fi

# Assign the environment argument to a variable
ENVIRONMENT=$1

# Fetch the secret value from AWS Secrets Manager
SECRET_NAME="${ENVIRONMENT}-app-deploy-data"
SECRET_VALUE=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query SecretString --output text)

# Check if the secret was fetched successfully
if [ $? -ne 0 ]; then
  echo "Failed to fetch secret: $SECRET_NAME"
  exit 1
fi

# Parse the JSON and export variables
export IMAGE_NAME=$(echo $SECRET_VALUE | jq -r '.IMAGE_NAME')
export ECR_REGISTRY=$(echo $SECRET_VALUE | jq -r '.ECR_REGISTRY')
export ECR_REPOSITORY=$(echo $SECRET_VALUE | jq -r '.ECR_REPOSITORY')
export ACCOUNT_ID=$(echo $SECRET_VALUE | jq -r '.ACCOUNT_ID')
export ECS_CLUSTER=$(echo $SECRET_VALUE | jq -r '.ECS_CLUSTER')
export ECS_REGION=$(echo $SECRET_VALUE | jq -r '.ECS_REGION')
export ECS_SERVICE=$(echo $SECRET_VALUE | jq -r '.ECS_SERVICE')
export ECS_TASK_DEFINITION=$(echo $SECRET_VALUE | jq -r '.ECS_TASK_DEFINITION')
export ECS_APP_CONTAINER_NAME=$(echo $SECRET_VALUE | jq -r '.ECS_APP_CONTAINER_NAME')
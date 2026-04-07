#!/bin/bash
set -e

IMAGE="$1"

# Refresh env from Secrets Manager
SECRETS=$(aws secretsmanager get-secret-value --secret-id public-cards/prod --region us-east-1 --query SecretString --output text)
echo "$SECRETS" | jq -r 'to_entries[] | "\(.key)=\(.value)"' > /opt/public-cards.env
echo PHX_SERVER=true >> /opt/public-cards.env
echo PORT=8080 >> /opt/public-cards.env
echo POOL_SIZE=10 >> /opt/public-cards.env

# Pull latest image
ECR_REGISTRY=$(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "$ECR_REGISTRY"
docker pull "$IMAGE"

# Restart container
docker stop public-cards 2>/dev/null || true
docker rm public-cards 2>/dev/null || true
INSTANCE_ID=$(ec2-metadata -i | cut -d' ' -f2)
docker run -d --name public-cards --restart unless-stopped --env-file /opt/public-cards.env --network host \
  --log-driver=awslogs --log-opt awslogs-region=us-east-1 --log-opt awslogs-group=/app/public-cards --log-opt awslogs-stream="$INSTANCE_ID" \
  "$IMAGE"

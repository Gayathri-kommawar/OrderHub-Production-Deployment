#!/usr/bin/env bash

set -e

REGISTRY="localhost:5000"
IMAGE_NAME="orderhub"
IMAGE_TAG="${1:-}"

CONTAINER_NAME="orderhub-prod"
HOST_PORT="8080"
CONTAINER_PORT="8080"

if [ -z "$IMAGE_TAG" ]; then
    echo "ERROR: Image tag is required."
    echo "Usage: ./deploy.sh <image-tag>"
    exit 1
fi

IMAGE="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "========================================"
echo "OrderHub Deployment"
echo "========================================"
echo "Image: ${IMAGE}"

echo ""
echo "Pulling exact immutable image..."
docker pull "${IMAGE}"

echo ""
echo "Stopping existing container if present..."
docker stop "${CONTAINER_NAME}" 2>/dev/null || true

echo ""
echo "Removing existing container if present..."
docker rm "${CONTAINER_NAME}" 2>/dev/null || true

echo ""
echo "Starting new production container..."
docker run -d \
    --name "${CONTAINER_NAME}" \
    -p "${HOST_PORT}:${CONTAINER_PORT}" \
    "${IMAGE}"

echo ""
echo "Waiting for application health..."

for i in {1..12}; do

    STATUS=$(docker inspect \
        --format='{{.State.Health.Status}}' \
        "${CONTAINER_NAME}" 2>/dev/null || echo "unknown")

    echo "Health status: ${STATUS}"

    if [ "${STATUS}" = "healthy" ]; then
        break
    fi

    if [ "${STATUS}" = "unhealthy" ]; then
        echo "ERROR: Container became unhealthy."
        docker logs "${CONTAINER_NAME}"
        exit 1
    fi

    sleep 5

    if [ "$i" -eq 12 ]; then
        echo "ERROR: Application did not become healthy."
        docker logs "${CONTAINER_NAME}"
        exit 1
    fi

done

echo ""
echo "Running smoke test..."

curl --fail --silent http://localhost:${HOST_PORT}/health
echo ""

curl --fail --silent http://localhost:${HOST_PORT}/
echo ""

curl --fail --silent http://localhost:${HOST_PORT}/orders
echo ""

echo ""
echo "========================================"
echo "Deployment successful"
echo "========================================"

echo "Deployed image:"
docker inspect --format='{{.Config.Image}}' "${CONTAINER_NAME}"

echo "Container:"
docker ps --filter "name=${CONTAINER_NAME}"
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

NEW_IMAGE="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "========================================"
echo "OrderHub Deployment"
echo "========================================"
echo "New image: ${NEW_IMAGE}"

OLD_IMAGE=""

if docker inspect "${CONTAINER_NAME}" >/dev/null 2>&1; then
    OLD_IMAGE=$(docker inspect --format='{{.Config.Image}}' "${CONTAINER_NAME}")
    echo "Previous image: ${OLD_IMAGE}"
else
    echo "No previous production container found."
fi

echo ""
echo "Pulling exact immutable image..."
docker pull "${NEW_IMAGE}"

echo ""
echo "Stopping existing production container..."
docker stop "${CONTAINER_NAME}" 2>/dev/null || true

echo ""
echo "Removing existing production container..."
docker rm "${CONTAINER_NAME}" 2>/dev/null || true

echo ""
echo "Starting new production container..."

if ! docker run -d \
    --name "${CONTAINER_NAME}" \
    -p "${HOST_PORT}:${CONTAINER_PORT}" \
    "${NEW_IMAGE}"; then

    echo "ERROR: New container failed to start."

    if [ -n "${OLD_IMAGE}" ]; then
        echo "Rolling back to ${OLD_IMAGE}..."

        docker run -d \
            --name "${CONTAINER_NAME}" \
            -p "${HOST_PORT}:${CONTAINER_PORT}" \
            "${OLD_IMAGE}"

        echo "Rollback container started."
    fi

    exit 1
fi

echo ""
echo "Waiting for application health..."

HEALTH_OK=false

for i in {1..12}; do

    STATUS=$(docker inspect \
        --format='{{.State.Health.Status}}' \
        "${CONTAINER_NAME}" 2>/dev/null || echo "unknown")

    echo "Health status: ${STATUS}"

    if [ "${STATUS}" = "healthy" ]; then
        HEALTH_OK=true
        break
    fi

    if [ "${STATUS}" = "unhealthy" ]; then
        break
    fi

    sleep 5
done

if [ "${HEALTH_OK}" != "true" ]; then

    echo ""
    echo "ERROR: New deployment failed health check."

    docker logs "${CONTAINER_NAME}" || true

    docker stop "${CONTAINER_NAME}" 2>/dev/null || true
    docker rm "${CONTAINER_NAME}" 2>/dev/null || true

    if [ -n "${OLD_IMAGE}" ]; then

        echo ""
        echo "========================================"
        echo "ROLLBACK STARTED"
        echo "========================================"

        docker run -d \
            --name "${CONTAINER_NAME}" \
            -p "${HOST_PORT}:${CONTAINER_PORT}" \
            "${OLD_IMAGE}"

        sleep 10

        echo "Rollback image:"
        docker inspect --format='{{.Config.Image}}' "${CONTAINER_NAME}"

        echo "Rollback health:"
        docker inspect --format='{{.State.Health.Status}}' "${CONTAINER_NAME}"

        echo "Rollback completed."
    fi

    exit 1
fi

echo ""
echo "Running smoke test..."

if ! curl --fail --silent http://localhost:${HOST_PORT}/health; then
    echo ""
    echo "ERROR: Smoke test failed."

    docker stop "${CONTAINER_NAME}" 2>/dev/null || true
    docker rm "${CONTAINER_NAME}" 2>/dev/null || true

    if [ -n "${OLD_IMAGE}" ]; then
        echo "Rolling back to ${OLD_IMAGE}..."

        docker run -d \
            --name "${CONTAINER_NAME}" \
            -p "${HOST_PORT}:${CONTAINER_PORT}" \
            "${OLD_IMAGE}"

        sleep 10

        echo "Rollback image:"
        docker inspect --format='{{.Config.Image}}' "${CONTAINER_NAME}"
    fi

    exit 1
fi

echo ""

echo "========================================"
echo "Deployment successful"
echo "========================================"

echo "Deployed image:"
docker inspect --format='{{.Config.Image}}' "${CONTAINER_NAME}"

echo "Health:"
docker inspect --format='{{.State.Health.Status}}' "${CONTAINER_NAME}"

echo "Container:"
docker ps --filter "name=${CONTAINER_NAME}"
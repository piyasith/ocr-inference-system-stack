#!/bin/bash

# exit immediately if any command fails
set -e

echo "Starting Docker Compose services..."
echo
docker-compose up -d

# wait 5 seconds to ensure containers are up
sleep 5
echo
echo "Docker containers started successfully!"
echo
# testing model server container
echo "Testing Model Server container..."

MODEL_RESPONSE=$(curl http://localhost:8080/metrics)
echo
echo "Model Server Response: $MODEL_RESPONSE"
echo
# testing gateway container
echo "Testing Gateway container..."

GATEWAY_RESPONSE=$(curl -s -X POST "http://localhost:8001/gateway/ocr" -F "image_file=@images.jpeg")
echo
echo "Gateway Test Image Response: $GATEWAY_RESPONSE"
echo

echo "Both containers are up and running!"
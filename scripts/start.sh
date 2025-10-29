#!/bin/bash
set -e
echo "Starting build workflow"

scripts/docker_initialize.sh
scripts/git.sh

DATESTAMP=$(date +%Y%m%d)

# run build
echo "[${BRANCH_NAME}] Building image: ${IMAGE_FULLNAME}"
if [ "$BRANCH_NAME" = "master" ] || [ "$BRANCH_NAME" = "main" ]
then
    docker build \
        -t ${IMAGE_FULLNAME}:latest \
        -t ${IMAGE_FULLNAME}:${DATESTAMP} \
        --pull \
        --push ./repo/
else
    docker build \
        -t ${IMAGE_FULLNAME}-test:${BRANCH_NAME} \
        --pull \
        --push ./repo/
fi

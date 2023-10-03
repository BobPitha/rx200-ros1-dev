#!/bin/bash
CONTAINER_NAME="$1"
USERNAME="$2"

while [[ $(docker exec -it ${CONTAINER_NAME} bash -c "[[ -f /.docker-setup-user-complete ]] && echo 'true'" | tr -d '\r') != "true" ]]; do
    echo "Waiting for ${CONTAINER_NAME} docker container setup to be complete"
    sleep 5
done

echo "Connecting to ${CONTAINER_NAME} docker container"
docker exec -it -e "TERM=xterm-256color" --user="${USERNAME}" -w /home/${USERNAME} ${CONTAINER_NAME} bash

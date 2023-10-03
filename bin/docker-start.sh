#!/bin/bash

if git rev-parse --git-dir > /dev/null 2>&1 ; then
    # we're in a git repo
    ROOT_DIR=`git rev-parse --show-toplevel`
else
    EXE_DIR=$(builtin cd $(dirname $0); pwd)
    if [ $(basename ${EXE_DIR}) == "bin" ] ; then
        ROOT_DIR=$(dirname ${EXE_DIR})
    else
        echo "ERROR: cannot determine root directory name. Make sure this script is running in the bin/ directory under the root"
        exit
    fi
fi

echo ROOT_DIR: ${ROOT_DIR}
echo EXE_DIR: ${EXE_DIR}

# Handle arguments
if [[ "$#" -lt 2 ]]; then
    echo $"ERROR: missing arguments."
    exit 1
fi

readonly IMAGE="$1"
readonly CONTAINER_NAME="$2"
if [[ "$#" -ge 3 ]]; then
    readonly USER_ARGS="$3"
fi
if [[ "$#" -ge 4 ]]; then
    readonly WORKSPACE_PATH="$4"
fi

echo IMAGE: $IMAGE
echo CONTAINER_NAME: $CONTAINER_NAME
echo USER_ARGS: $USER_ARGS
echo WORKSPACE_PATH: $WORKSPACE_PATH

readonly DOCKER_COMPOSE_NETWORK="${CONTAINER_NAME}-network"
readonly DOCKER_COMPOSE_VOLUME="${CONTAINER_NAME}-volume"

echo DOCKER_COMPOSE_NETWORK: $DOCKER_COMPOSE_NETWORK
echo DOCKER_COMPOSE_VOLUME: $DOCKER_COMPOSE_VOLUME

running_container_id=$(docker ps --format "{{.ID}}" --filter name=${CONTAINER_NAME})

if [[ -z "${running_container_id}" ]]; then

    # check that the docker image is already built
    if [ -z $(docker images -q ${IMAGE}) ]; then
        echo "Attempting to run image $IMAGE, but it does not exist locally."
        exit 1
    fi

    # Workspace directory
    if [[ -d "${WORKSPACE_PATH}" ]]; then
        workspace_mounts="--volume=${WORKSPACE_PATH}:/workspace"

        for symbolic_link in $(find ${WORKSPACE_PATH} -maxdepth 1 -type l); do
            abs=$(realpath "${symbolic_link}")
            workspace_mounts="${workspace_mounts} --volume="${abs}":/workspace/$(basename ${symbolic_link})"
        done
    else
        echo "WORKSPACE_PATH does not specify an existing workspace directory."
    fi

    # set up X-Windows to allow docker to display GUIs
    readonly XSOCK=/tmp/.X11-unix
    readonly XAUTH=$(mktemp /tmp/.docker.xauth.XXXXX)
    touch $XAUTH
    xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $SAUTH nmerge -

    if [[ -z $(docker network ls --filter NAME=${DOCKER_COMPOSE_NETWORK} -q) ]]; then
        echo "Starting ${DOCKER_COMPOSE_NETWORK} network"
        docker network create ${DOCKER_COMPOSE_NETWORK}
    fi

    if [[ -z $(docker volume ls --filter NAME=${DOCKER_COMPOSE_VOLUME} -q) ]]; then
        echo "Creating volume ${DOCKER_COMPOSE_VOLUME}"
        docker volume create ${DOCKER_COMPOSE_VOLUME}
    fi
    
    echo "Starting a new ${CONTAINER_NAME} docker container from image ${IMAGE}"
    readonly HOST_UID=$(id -u)
    readonly HOST_GID=$(id -g)
    ( set -x;
        docker run \
        --privileged \
        --rm \
        --tty \
        --detach \
        --network host \
        --name ${CONTAINER_NAME} \
        --hostname ${CONTAINER_NAME} \
        --add-host ${CONTAINER_NAME}:127.0.0.1 \
        --env="DISPLAY" \
        --env="XAUTHORITY=${XAUTH}" \
        --env="QT_X11_NO_MITSHM=1" \
        --env="HOST_UID=${HOST_UID}" \
        --env="HOST_GID=${HOST_GID}" \
        --volume=$XSOCK:$XSOCK:rw \
        --volume=$XAUTH:$XAUTH:rw \
        $USER_ARGS \
        $workspace_mounts \
        $arch_args \
        $IMAGE \
        || exit 1

    )
    echo ""

else
    echo "Container ${CONTAINER_NAME} running."
    exit

    running_image_id=$(docker inspect ${running_container_id} --format "{{.Image}}")
    latest_image_id=$(docker inspect $IMAGE --format "{{.Id}}")

    if [[ "${running_image_id}" != "${latest_image_id}" ]]; then
        echo "$(tput setaf 202)***** A container for ${CONTAINER_NAME} is running, but it is not the most recent image."
        echo "$(tput setaf 214)***** You might have built a new image but not restarted your container.$(tput sgr0)"
    fi
fi

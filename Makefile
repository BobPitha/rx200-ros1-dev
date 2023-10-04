IS_GIT_DIR := $$( if git rev-parse --git-dir > /dev/null 2>&1 ; then echo yes ; else echo no ; fi )
REPOSITORY_ROOT := $$( if [ ${IS_GIT_DIR} = "yes" ] ; then git rev-parse --show-toplevel ; else dirname $(realpath $(firstword $(MAKEFILE_LIST))) ; fi )
VERSION := $$( if [ ${IS_GIT_DIR} = "yes" ] ; then git rev-parse --short HEAD ; else echo x ; fi )
VERSION_LONG := $$( if [ ${IS_GIT_DIR} = "yes" ] ; then git rev-parse HEAD ; else echo xxx ; fi )

DOCKER_ROOT_IMAGE := ubuntu:20.04
ORGANIZATION := ma
PROJECT := rx200-ros1-dev
DOCKER_IMAGE_TAG_ROOT := ${ORGANIZATION}/${PROJECT}_img
DOCKER_CONTAINER_NAME_ROOT := ${PROJECT}
SERVER_USER := ma
DOCKER_RUN_USER_ARGS := ${DOCKER_RUN_USER_ARGS} $\
			--volume=${REPOSITORY_ROOT}/shell_state/Code:/home/${SERVER_USER}/.config/Code $\
			--volume=${HOME}/.ssh:/home/${SERVER_USER}/.ssh
WORKSPACE_PATH := ${REPOSITORY_ROOT}/workspace

test:
	@echo "This is a test"
	@echo "Organization: ${ORGANIZATION}"
	@echo "Project: ${PROJECT}"
	@echo "Image: ${DOCKER_IMAGE_TAG_ROOT}"
	@echo "Container: ${DOCKER_CONTAINER_NAME_ROOT}"
	@echo "Is git dir: ${IS_GIT_DIR}"
	@echo "Repo: ${REPOSITORY_ROOT}"
	@echo "Version: ${VERSION}"

build:
	@echo "******"
	@echo "******"
	@echo "****** 'make build' is deprecated; please use 'make dev' instead."
	@echo "******"
	@echo "******"


base:
	bin/banner Docker *BASE* build ${DOCKER_IMAGE_TAG_ROOT}:v${VERSION}
	docker build \
	    --network=host \
        -t ${DOCKER_IMAGE_TAG_ROOT}-base:v${VERSION} \
        -t ${DOCKER_IMAGE_TAG_ROOT}-base:latest \
        --build-arg FROM_IMAGE=${DOCKER_ROOT_IMAGE} \
        --build-arg SERVER_USER=${SERVER_USER} \
        ${CACHE_OPTION} -f Dockerfile-base .

dev: base
	bin/banner Docker *DEVELOPMENT* build ${DOCKER_IMAGE_TAG_ROOT}
	docker build \
	 	--network=host \
        -t ${DOCKER_IMAGE_TAG_ROOT}-dev:v${VERSION} \
		-t ${DOCKER_IMAGE_TAG_ROOT}-dev:latest \
        --build-arg FROM_IMAGE=${DOCKER_IMAGE_TAG_ROOT}-base:latest \
 		--build-arg SERVER_USER=${SERVER_USER} \
 		${CACHE_OPTION} -f Dockerfile-dev .

shell:
	@${REPOSITORY_ROOT}/bin/docker-start.sh ${DOCKER_IMAGE_TAG_ROOT}-dev:v${VERSION} ${DOCKER_CONTAINER_NAME_ROOT} "${DOCKER_RUN_USER_ARGS}" "${WORKSPACE_PATH}"
	@${REPOSITORY_ROOT}/bin/docker-shell.sh ${DOCKER_CONTAINER_NAME_ROOT} ${SERVER_USER} || true

stop:
	docker kill ${DOCKER_CONTAINER_NAME_ROOT}

clean:
	@echo "removing containers"
	@echo $$(docker ps -q --filter "NAME=${DOCKER_CONTAINER_NAME_ROOT}")
	@docker rm $$(docker ps -q --filter "NAME=${DOCKER_CONTAINER_NAME_ROOT}") >/dev/null 2>&1 || echo "   no containers to remove"



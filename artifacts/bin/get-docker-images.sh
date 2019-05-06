#!/bin/bash -eu
# Copyright London Stock Exchange Group All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# This script pulls docker images from the Dockerhub hyperledger repositories

# set the default Docker namespace and tag
DOCKER_NS=hyperledger
ARCH=amd64
#VERSION=1.2.1-snapshot-73404f5
VERSION=1.2.0
BASE_DOCKER_TAG=amd64-0.4.10

# set of Hyperledger Fabric images
FABRIC_IMAGES=(fabric-peer fabric-orderer fabric-ccenv fabric-tools)

for image in ${FABRIC_IMAGES[@]}; do
  echo "Pulling ${DOCKER_NS}/$image:${ARCH}-${VERSION}"
#  docker pull ${DOCKER_NS}/$image:${ARCH}-${VERSION}
# docker tag ${DOCKER_NS}/$image:${ARCH}-${VERSION} ${DOCKER_NS}/$image:latest
 docker tag ${DOCKER_NS}/$image:1.4.0 ${DOCKER_NS}/$image:latest
#  docker tag ${DOCKER_NS}/$image:latest ${DOCKER_NS}/$image:1.4.0
done

THIRDPARTY_IMAGES=(fabric-kafka fabric-zookeeper fabric-couchdb fabric-baseos)

for image in ${THIRDPARTY_IMAGES[@]}; do
  echo "Pulling ${DOCKER_NS}/$image:${BASE_DOCKER_TAG}"
#  docker pull ${DOCKER_NS}/$image:${BASE_DOCKER_TAG}
 docker tag ${DOCKER_NS}/$image:1.4.0 ${DOCKER_NS}/$image:latest
# docker tag ${DOCKER_NS}/$image:${BASE_DOCKER_TAG}  ${DOCKER_NS}/$image:latest
#  docker tag ${DOCKER_NS}/$image:latest  ${DOCKER_NS}/$image:1.4.0
done

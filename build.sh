#!/bin/bash

export APACHEDS_VERSION=2.0.0.AM26

# Define the remote Docker registry to push the final image to.
DOCKER_REGISTRY=${DOCKER_REGISTRY:-'ghcr.io/ldapjs/docker-test-apacheds'}

# Set to 1 to push the final image to the remote registry, e.g.:
# `PUSH=1 ./build.sh`
#
# Remember to authenticate to the registry:
# https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-to-the-container-registry
PUSH=${PUSH:-0}

# First input = local dest name
# Second input = URL
function downloadPackage() {
  mkdir -p packages 2>&1 > /dev/null
  if [ ! -e packages/${1} ]; then
    echo "Downloading ${1}..."
      curl --progress-bar -L -o packages/${1} ${2}
  fi
}

function trap_handler() {
  return_value=$?
  if [ ${return_value} -ne 0 ]; then
    echo 'Build failed!'
    exit ${return_value}
  fi
}
trap "trap_handler" INT TERM EXIT ERR

APACHEDS_URL=https://dlcdn.apache.org//directory/apacheds/dist/${APACHEDS_VERSION}/apacheds-${APACHEDS_VERSION}-amd64.deb
INIT_URL=$(
  curl -s https://api.github.com/repos/Yelp/dumb-init/releases | \
  jq -r 'map(select(.draft == false and .prerelease == false)) | .[0].assets | map(select(.name | test("dumb-init_.+?_x86_64"))) | .[0].browser_download_url'
)

downloadPackage apacheds.deb ${APACHEDS_URL}
downloadPackage dumb-init ${INIT_URL}
chmod +x packages/dumb-init

docker build -t apacheds-bootstrap -f Dockerfile.bootstrap .

if [ ! -d build_out ]; then
  mkdir build_out
fi

docker run --rm \
  -v $(pwd)/build_out:/build_out \
  apacheds-bootstrap

docker build -t apacheds -f Dockerfile.final .

d=$(date +'%Y-%m-%d')
docker tag apacheds ${DOCKER_REGISTRY}/apacheds:${d}
docker tag apacheds ${DOCKER_REGISTRY}/apacheds:latest

if [ ${PUSH} -eq 1 ]; then
  docker push ${DOCKER_REGISTRY}/apacheds:${d}
  docker push ${DOCKER_REGISTRY}/apacheds:latest
fi

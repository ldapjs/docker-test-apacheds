#!/bin/bash

export APACHEDS_VERSION=2.0.0.AM26

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

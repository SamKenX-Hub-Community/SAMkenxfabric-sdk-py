#! /bin/bash -ue
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

set -o pipefail -o noglob

# pull fabric core images
dockerFabricPull() {
  local img_tag=$1
  for images in peer orderer ca ccenv tools; do
      local hlf_img=hyperledger/fabric-$images:$img_tag
      echo "==> Check IMAGE: $hlf_img"
      if [[ -z "$(docker images -q $hlf_img 2> /dev/null)" ]]; then  # not exist
          docker pull $hlf_img
      else
          echo "Image: $hlf_img already exists locally"
      fi
  done
}

# checking local version
echo "===> Checking Docker and Docker-Compose version"
docker version
echo
docker-compose -v

if type tox; then
   tox_version=$(tox --version)
   echo "====> tox is already installed $tox_version"
   echo
else
   echo "====> install tox here"
   echo
   pip install tox
fi

echo "===> Installing couchdb"
sudo apt update
sudo apt install snapd
sudo snap install couchdb

img_tag=1.4.6
baseimage_tag=0.4.16
echo "=====> Pulling fabric Images with tag= ${img_tag}, baseimage_tag= ${baseimage_tag}"
dockerFabricPull ${img_tag}
img=hyperledger/fabric-baseimage:$baseimage_tag
[ -z "$(docker images -q $img 2> /dev/null)" ] && docker pull $img
img=hyperledger/fabric-baseos:$baseimage_tag
[ -z "$(docker images -q $img 2> /dev/null)" ] && docker pull $img

project_version=1.4.6
echo "=====> Downloading fabric binaries with version= ${project_version}"
if ! type configtxgen; then
    if  [[ ! -e fabric-bin/bin/configtxgen ]]; then
        echo "configtxgen doesn't exits."
        mkdir -p fabric-bin
        kernel=$(uname -s | tr '[:upper:]' '[:lower:]' | sed 's/mingw64_nt.*/windows/')
        machine=$(uname -m | sed 's/x86_64/amd64/g' | tr '[:upper:]' '[:lower:]')
        platform=${kernel}-${machine}
        echo "===> Downloading '${platform}' specific fabric binaries"
        bin_url="https://github.com/hyperledger/fabric/releases/download/v${project_version}"
        bin_url+="/hyperledger-fabric-${platform}-${project_version}.tar.gz"
        if ! curl -L $bin_url | tar -C fabric-bin -vxz; then
            echo "Binary download failed."
            exit 1
        fi
    fi
fi

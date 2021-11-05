#!/bin/bash
# Download kvm images builded with https://github.com/goffinet/packer-kvm from http://download.goffinet.org/kvm/

#imagename="debian7 debian8 centos7 centos8 ubuntu1604 bionic metasploitable kali arch"
which curl > /dev/null || ( echo "Please install curl" && exit )
imagename=($(curl -qks http://download.goffinet.org/kvm/imagename))
image="$1"
url=http://download.goffinet.org/kvm/
destination=/var/lib/libvirt/images/
parameters=$#
wd=$PWD
force="$2"

question () {
echo "WARN : Do you want anyway download this file ${image}.qcow2 ?"
read -r -p "Are you sure? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY])
        sleep 1
        ;;
    *)
        exit
        ;;
esac
}

download_image () {
if [ "${force}" != "--force" ] ; then
  question
fi
curl -k ${url}${image}.qcow2 -o ${destination}${image}.qcow2
curl -k ${url}${image}.qcow2.md5sum -o ${destination}${image}.qcow2.md5sum
cd ${destination}
md5sum -c ${image}.qcow2.md5sum
rm -rf ${image}.qcow2.md5sum
cd ${wd}
}

usage () {
  echo "-------------------------------------------------------"
  echo "This script download automatically KVM images"
  echo "from http://download.goffinet.org/kvm."
  echo ""
  echo "Usage:"
  echo "  $0 image_name [--force]"
  echo ""
  echo "Where the \"image_name\" parameter can be:"
  echo "${imagename[*]}"
  echo "The option \"--force\" does not ask for any confirmation."
  echo ""
  echo "Examples:"
  echo "  $0 ${imagename[0]} --force"
  echo "  $0 ${imagename[1]}"
  echo "-------------------------------------------------------"
}

if [ ${parameters} -lt 1 ] ; then
  usage
  echo "ERROR: Please provide an image name."
  exit
fi
if grep -qvw "${image}" <<< "${imagename[*]}" ; then
  usage
  echo "ERROR: Please provide a valid image name."
  exit
fi
if [ ${parameters} -gt 2 ] ; then
  usage
  echo "ERROR: Too much args."
  exit
fi
if [ -f ${destination}${image}.qcow2  ] ; then
  echo "WARN: The image ${destination}${image}.qcow2 already exists."
  cd ${destination}
  remote_md5="$(curl -ks ${url}${image}.qcow2.md5sum)"
  cd ${destination}
  local_md5="$(md5sum ${image}.qcow2)"
  cd ${wd}
    if [ "${remote_md5}" = "${local_md5}" ] ; then
      echo "WARN: The local image is exactly the same than the remote image."
      download_image
    else
      echo "WARN: The local image differs from the remote image."
      download_image
fi
else
  echo "WARN: The image ${destination}${image}.qcow2 does not exist."
  download_image
fi

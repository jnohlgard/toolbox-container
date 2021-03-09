#!/bin/sh
# Common reusable parts for toolbox builder scripts

arch=$(uname -m)

# Alternative names for architectures
case ${arch} in
  x86_64)
    altarch=amd64
    ;;
  aarch64)
    altarch=arm64
    ;;
  *)
    altarch=${arch}
    ;;
esac

dnf_install_from_list_files() {
  container=${1}; shift
  # Read all lines in the given files, stripping comments that begin with # (hash symbol)
  ( for f in "$@"; do
    sed -e '/^[ \t]*#/d' -e 's/[ \t]#.*$//' < "${f}"
  done ) | xargs buildah run ${container} dnf -y install
}

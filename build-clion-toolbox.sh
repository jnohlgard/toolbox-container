#!/bin/bash
set -euxo pipefail

clion_version=2020.3
clion_sha256=ffc862511bf80debb80f9d60d2999b02e32b7c3cbb8ac25a4c0efc5b9850124f

tag=clion-toolbox:${clion_version}

base_image=registry.fedoraproject.org/f33/fedora-toolbox:33

clion_url=https://download.jetbrains.com/cpp/CLion-${clion_version}.tar.gz
clion_archive=CLion-${clion_version}.tar.gz

resume_download_to='curl -R -C - -f -L -o'
#resume_download_to='wget --timestamping -c -O'

# Get the CLion archive from JetBrains server unless we already have it
if ! printf '%s *%s\n' "${clion_sha256}" "${clion_archive}" | sha256sum -c; then
  printf '%s not found, will download...\n' "${clion_archive}" >&2
  ${resume_download_to} "${clion_archive}" "${clion_url}"
  printf '%s *%s\n' "${clion_sha256}" "${clion_archive}" | sha256sum -c
fi

# Create a container
container=$(buildah from "${base_image}")
buildah config --label maintainer="Joakim Nohlgård <joakim@nohlgard.se>" ${container}

# CLion bundles its own JRE build based on OpenJDK 11, but we still need a
# bunch of X11 libraries to run it. The easiest solution is to install OpenJDK
# on the container which will pull in all of those deps
buildah run ${container} dnf install -y java-11-openjdk
buildah run ${container} dnf clean all

buildah add --add-history ${container} "${clion_archive}" /opt/
buildah commit --rm ${container} ${tag}

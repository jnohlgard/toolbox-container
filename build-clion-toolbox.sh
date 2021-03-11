#!/bin/bash
set -euxo pipefail
mydir=$(cd "$(dirname "$0")"; pwd)

: ${CLION_VERSION:=2020.3.2}
: ${BASE_IMAGE:=registry.fedoraproject.org/f33/fedora-toolbox:33}

if [ $# -ne 1 ]; then
  >&2 printf 'Usage: %s <destination_image_name>\n\n' "$0"
  >&2 printf 'Optional environment variables:\n'
  >&2 printf '  - CLION_VERSION selects which version to install (%s)\n' "${CLION_VERSION}"
  >&2 printf '  - BASE_IMAGE selects the base image (%s)\n' "${BASE_IMAGE}"
  exit 1
fi

dest_image=$1; shift
if [ -z "${dest_image}" ]; then
  >&2 printf 'Missing destination image name\n'
  exit 1
fi

if [ -n "${dest_image##*:*}" ]; then
  # Does not contain a colon char, add the CLion version as tag
  dest_image=${dest_image}:${CLION_VERSION}
fi

clion_archive=CLion-${CLION_VERSION}.tar.gz

dist_dir=${mydir}/dist
manifest_downloader=${mydir}/download-verify/manifest-download.sh
manifest=${dist_dir}/Jetbrains.manifest

# Ensure the CLion package is downloaded
( cd "${dist_dir}" && "${manifest_downloader}" "${manifest}" "${clion_archive}" )

# Create a container
container=$(buildah from --pull "${BASE_IMAGE}")
buildah config --label maintainer="Joakim Nohlgård <joakim@nohlgard.se>" ${container}

# CLion bundles its own JRE build based on OpenJDK 11, but we still need a
# bunch of X11 libraries to run it. The easiest solution is to install OpenJDK
# on the container which will pull in all of those deps.
# flatpak-xdg-utils provides the flatpak-xdg-open wrapper that allows us to open
# URLs in the host web browser using flatpak-xdg-open.
# JCEF (Chrome embedded) requires some additional libraries that we need to add
# here as well
buildah run ${container} dnf install -y java-11-openjdk flatpak-xdg-utils nss libX11-xcb libdrm mesa-libgbm
buildah run ${container} dnf clean all

buildah add ${container} "${dist_dir}/${clion_archive}" /opt/
buildah config --env PATH="$(buildah run $container printenv PATH):/opt/clion-${CLION_VERSION}/bin/" ${container}
buildah commit --rm ${container} ${dest_image}

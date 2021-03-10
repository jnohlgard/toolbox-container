#!/bin/bash
set -euxo pipefail

clion_version=2020.3.2

tag=clion-toolbox:${clion_version}

base_image=registry.fedoraproject.org/f33/fedora-toolbox:33

clion_archive=CLion-${clion_version}.tar.gz

mydir=$(cd "$(dirname "$0")"; pwd)

dist_dir=${mydir}/dist
manifest_downloader=${mydir}/download-verify/manifest-download.sh
manifest=${dist_dir}/Jetbrains.manifest

# Ensure the CLion package is downloaded
( cd "${dist_dir}" && "${manifest_downloader}" "${manifest}" "${clion_archive}" )

# Create a container
container=$(buildah from --pull "${base_image}")
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

buildah add --add-history ${container} "${dist_dir}/${clion_archive}" /opt/
buildah commit --rm ${container} ${tag}

#!/bin/bash
set -euxo pipefail
mydir=$(cd "$(dirname "$0")"; pwd)

dnf_packages_dir=${mydir}/dev-packages.d

source "${mydir}/common.inc.sh"

toolbox_tag=dev-toolbox
base_image=registry.fedoraproject.org/fedora-toolbox:35

# Create a container
container=$(buildah from --pull "${base_image}")
buildah config --label maintainer="Joakim Nohlgård <joakim@nohlgard.se>" ${container}

dnf_install_from_list_files ${container} "${dnf_packages_dir}"/*.dnf.txt
buildah run ${container} dnf clean all
buildah commit --rm ${container} ${toolbox_tag}

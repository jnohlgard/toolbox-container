#!/bin/bash
set -euxo pipefail
mydir=$(cd "$(dirname "$0")"; pwd)

# Using an EAP build to avoid the license requirement
: ${CLION_VERSION:=211.6305.15}

dnf_user_packages_dir=${mydir}/user-packages.d

"${mydir}/build-riot-toolbox.sh"

CLION_VERSION="${CLION_VERSION}" BASE_IMAGE=riotbuild:latest "${mydir}/build-clion-toolbox.sh" "riot-clion:${CLION_VERSION}"

source "${mydir}/common.inc.sh"

if [ -d "${dnf_user_packages_dir}" ]; then
  user_dnf_lists=$(find "${dnf_user_packages_dir}" -name '*.dnf.txt' -print 2>/dev/null)

  if [ -n "${user_dnf_lists}" ]; then
    # Create a container
    container=$(buildah from "riot-clion:${CLION_VERSION}")

    dnf_install_from_list_files ${container} ${user_dnf_lists}
    buildah run ${container} dnf clean all
    buildah commit --rm ${container} riot-user-toolbox
  fi
fi

#!/bin/bash
set -euxo pipefail
mydir=$(cd "$(dirname "$0")"; pwd)

source "${mydir}/common.inc.sh"

toolbox_tag=dev-toolbox
base_image=registry.fedoraproject.org/fedora-toolbox:35
dnf_packages_dir=${mydir}/dev-packages.d
dnf_user_packages_dir=${mydir}/user-packages.d

arm_gcc_version=10.3-2021.10
riscv_gcc_version=10.2.0-2020.12.8

arm_gcc_package=gcc-arm-none-eabi-${arm_gcc_version}-${arch}-linux.tar.bz2
riscv_gcc_package=riscv64-unknown-elf-toolchain-${riscv_gcc_version}-${arch}-linux-centos6.tar.gz

dist_dir=${mydir}/dist
manifest_downloader=${mydir}/download-verify/manifest-download.sh
manifest=${dist_dir}/RIOT.manifest

opt_packages=(
  "${arm_gcc_package}"
  "${riscv_gcc_package}"
)

# Ensure packages are downloaded
( cd "${dist_dir}" && "${manifest_downloader}" "${manifest}" "${opt_packages[@]}" )

# Create a container
container=$(buildah from --pull "${base_image}")
buildah config --label maintainer="Joakim Nohlgård <joakim@nohlgard.se>" ${container}

dnf_install_from_list_files ${container} "${dnf_packages_dir}"/*.dnf.txt
if [ -d "${dnf_user_packages_dir}" ]; then
  user_dnf_lists=$(find "${dnf_user_packages_dir}" -name '*.dnf.txt' -print 2>/dev/null)

  if [ -n "${user_dnf_lists}" ]; then
    dnf_install_from_list_files ${container} ${user_dnf_lists}
  fi
fi
buildah run ${container} dnf clean all
( cd "${dist_dir}" && buildah add ${container} "${opt_packages[@]}" /opt/ )
buildah config --env PATH="$(buildah run $container printenv PATH):/opt/gcc-arm-none-eabi-${arm_gcc_version}/bin/:/opt/riscv64-unknown-elf-toolchain-${riscv_gcc_version}-${arch}-linux-centos6/bin" ${container}
buildah commit --rm ${container} ${toolbox_tag}
